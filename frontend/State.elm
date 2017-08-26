module State exposing (..)

import Dict exposing (Dict)
import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Phoenix.Presence
    exposing
        ( PresenceState
        , syncState
        , syncDiff
        , presenceStateDecoder
        , presenceDiffDecoder
        )
import Json.Encode
import Json.Decode
import Json.Decode exposing (int, string, float, bool, Decoder, list, dict)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Debug
import Navigation
import Routing exposing (parseLocation)
import Types
    exposing
        ( Msg
        , Game
        , Player
        , Presence
        , Model
        , Route
        )


initialModel : Model
initialModel =
    { name = ""
    , gameCode = ""
    , gameCodeInput = ""
    , nameInput = ""
    , textInput = ""
    , storySegments = []
    , playerRef = ""
    , players = Dict.empty
    , inProgress = False
    , currentPlayer = Nothing
    , alertMessage = Nothing
    , history = []
    , route = Types.HomeRoute
    , socket =
        Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
            |> Phoenix.Socket.withDebug
    , presences = Dict.empty
    }


modelFromLocation : Navigation.Location -> Model -> Model
modelFromLocation location model =
    { model
        | history = location :: model.history
        , route = parseLocation location
    }


currentPlayerStateDecoder : Decoder Types.CurrentPlayerState
currentPlayerStateDecoder =
    decode Types.CurrentPlayerState
        |> required "text_input" string


gameDecoder : Decoder Game
gameDecoder =
    decode Game
        |> required "game_code" string
        |> required "in_progress" bool
        |> optional "current_player" (Json.Decode.map Just string) Nothing
        |> optional "story" (list storySegmentDecoder) []


playerDecoder : Decoder Player
playerDecoder =
    decode Types.Player
        |> required "ref" string
        |> optional "name" string ""


storySegmentDecoder : Decoder Types.StorySegment
storySegmentDecoder =
    decode Types.StorySegment
        |> required "ref" string
        |> required "text" string


gameAndPlayersDecoder : Decoder Types.GameAndPlayers
gameAndPlayersDecoder =
    decode Types.GameAndPlayers
        |> required "game_code" string
        |> required "players" (dict playerDecoder)


presenceDecoder : Decoder Presence
presenceDecoder =
    decode Types.Presence
        |> required "ref" string
        |> required "online_at" string


handleNewGameRequest : Json.Encode.Value -> Msg
handleNewGameRequest value =
    -- Todo: this doesn't handle reseting game params.
    -- We can probably move this handler to the update function so that
    -- we have access to update the model.
    case Json.Decode.decodeValue gameDecoder value of
        Ok game ->
            Types.JoinGame game.gameCode

        Err error ->
            Types.DisplayError error


handleCurrentPlayerUpdate : Json.Encode.Value -> Msg
handleCurrentPlayerUpdate value =
    case Json.Decode.decodeValue playerDecoder value of
        Ok player ->
            Types.UpdatePlayer player

        Err error ->
            Types.DisplayError error


getGameChannel : String -> String
getGameChannel =
    (++) "game:"


mainChannel : String
mainChannel =
    "game:main"


registerPlayerParams : String -> Json.Encode.Value
registerPlayerParams name =
    Json.Encode.object [ ( "name", Json.Encode.string name ) ]


registerTextInputParams : String -> Json.Encode.Value
registerTextInputParams text =
    Json.Encode.object [ ( "text_input", Json.Encode.string text ) ]


handleRouting : Model -> ( Model, Cmd Msg )
handleRouting model =
    case model.route of
        Types.LobbyRoute gameCode ->
            let
                channelName =
                    getGameChannel gameCode

                channel =
                    Phoenix.Channel.init channelName
                        |> Phoenix.Channel.onJoin Types.HandleGameJoin

                ( socket, cmd ) =
                    Phoenix.Socket.join channel
                        (model.socket
                            |> Phoenix.Socket.on "presence_state" channelName Types.HandlePresenceState
                            |> Phoenix.Socket.on "presence_diff" channelName Types.HandlePresenceDiff
                            |> Phoenix.Socket.on "player:update" channelName Types.HandlePlayerUpdate
                            |> Phoenix.Socket.on "game:start" channelName Types.HandleGameStart
                            |> Phoenix.Socket.on "game:receive_input" channelName Types.HandleTextInputUpdate
                            |> Phoenix.Socket.on "game:submit_segment" channelName Types.HandleSegmentSubmission
                        )
            in
                ( { model | socket = socket, gameCode = gameCode }
                , Cmd.batch
                    ([ Cmd.map Types.PhoenixMsg cmd
                     , gameCode |> Routing.gamePath |> Navigation.newUrl
                     ]
                    )
                )

        _ ->
            model ! []


handleDecoderError : String -> Model -> ( Model, Cmd Msg )
handleDecoderError error model =
    let
        _ =
            Debug.log "Error" error
    in
        model ! []


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        --
        -- Navigation
        Types.UrlChange location ->
            ( modelFromLocation location model, Cmd.none )

        Types.SetGameState route ->
            handleRouting { model | route = route }

        --
        -- Alerts
        Types.DisplayError error ->
            { model | alertMessage = Just error } ! []

        Types.CloseAlert ->
            { model | alertMessage = Nothing } ! []

        --
        -- Passive State Handling
        Types.JoinMainChannel ->
            let
                channel =
                    Phoenix.Channel.init mainChannel

                ( socket, cmd ) =
                    Phoenix.Socket.join channel model.socket
            in
                ( { model | socket = socket }
                , Cmd.map Types.PhoenixMsg cmd
                )

        --
        -- Game Events
        Types.JoinGame gameCode ->
            update
                (Types.SetGameState (Types.LobbyRoute gameCode))
                model

        Types.UpdatePlayer player ->
            { model | name = player.name, playerRef = player.ref } ! []

        --
        -- Form Submission
        Types.SubmitGameCode ->
            update
                (Types.JoinGame model.gameCodeInput)
                model

        Types.SubmitStorySegment ->
            let
                push =
                    getGameChannel model.gameCode
                        |> Phoenix.Push.init "game:submit_segment"
                        |> Phoenix.Push.withPayload (registerTextInputParams model.textInput)

                ( socket, cmd ) =
                    Phoenix.Socket.push push model.socket
            in
                ( { model | socket = socket }
                , Cmd.map Types.PhoenixMsg cmd
                )

        Types.SubmitName ->
            let
                push =
                    getGameChannel model.gameCode
                        |> Phoenix.Push.init "player:update"
                        |> Phoenix.Push.withPayload (registerPlayerParams model.nameInput)
                        |> Phoenix.Push.onOk handleCurrentPlayerUpdate

                ( socket, cmd ) =
                    Phoenix.Socket.push push model.socket
            in
                ( { model | socket = socket }
                , Cmd.map Types.PhoenixMsg cmd
                )

        --
        -- Input Handling
        Types.UpdateInputGameCode gameCode ->
            { model | gameCodeInput = gameCode } ! []

        Types.UpdateInputName name ->
            { model | nameInput = name } ! []

        Types.UpdateInputText text ->
            let
                push =
                    getGameChannel model.gameCode
                        |> Phoenix.Push.init "game:receive_input"
                        |> Phoenix.Push.withPayload (registerTextInputParams text)

                ( socket, cmd ) =
                    Phoenix.Socket.push push model.socket
            in
                ( { model | socket = socket, textInput = text }
                , Cmd.map Types.PhoenixMsg cmd
                )

        --
        -- UI Events
        Types.TriggerNewGame ->
            let
                push =
                    Phoenix.Push.init "game:new" mainChannel
                        |> Phoenix.Push.onOk handleNewGameRequest

                ( socket, cmd ) =
                    Phoenix.Socket.push push model.socket
            in
                ( { model | socket = socket }
                , Cmd.map Types.PhoenixMsg cmd
                )

        Types.DeleteName ->
            { model | name = "" } ! []

        Types.StartGame ->
            let
                push =
                    getGameChannel model.gameCode
                        |> Phoenix.Push.init "game:start"

                ( socket, cmd ) =
                    Phoenix.Socket.push push model.socket
            in
                ( { model | socket = socket }
                , Cmd.map Types.PhoenixMsg cmd
                )

        --
        -- Sockets
        Types.PhoenixMsg msg ->
            let
                ( socket, cmd ) =
                    Phoenix.Socket.update msg model.socket
            in
                ( { model | socket = socket }
                , Cmd.map Types.PhoenixMsg cmd
                )

        Types.HandlePresenceState raw ->
            case Json.Decode.decodeValue (presenceStateDecoder presenceDecoder) raw of
                Ok presenceState ->
                    let
                        newPresenceState =
                            model.presences |> syncState presenceState
                    in
                        { model | presences = newPresenceState } ! []

                Err error ->
                    handleDecoderError error model

        Types.HandlePresenceDiff raw ->
            case Json.Decode.decodeValue (presenceDiffDecoder presenceDecoder) raw of
                Ok presenceDiff ->
                    let
                        newPresenceState =
                            model.presences |> syncDiff presenceDiff
                    in
                        { model | presences = newPresenceState } ! []

                Err error ->
                    handleDecoderError error model

        Types.HandlePlayerUpdate raw ->
            case Json.Decode.decodeValue playerDecoder raw of
                Ok player ->
                    let
                        newPlayers =
                            Dict.update player.ref (\_ -> Just player) model.players
                    in
                        { model | players = newPlayers } ! []

                Err error ->
                    handleDecoderError error model

        Types.HandleGameJoin raw ->
            case Json.Decode.decodeValue gameAndPlayersDecoder raw of
                Ok gameAndPlayers ->
                    { model | players = gameAndPlayers.players } ! []

                Err error ->
                    handleDecoderError error model

        Types.HandleGameStart raw ->
            case Json.Decode.decodeValue gameDecoder raw of
                Ok game ->
                    { model | inProgress = game.inProgress, currentPlayer = game.currentPlayer } ! []

                Err error ->
                    handleDecoderError error model

        Types.HandleTextInputUpdate raw ->
            case Json.Decode.decodeValue currentPlayerStateDecoder raw of
                Ok currentPlayerState ->
                    { model | textInput = currentPlayerState.textInput } ! []

                Err error ->
                    handleDecoderError error model

        Types.HandleSegmentSubmission raw ->
            case Json.Decode.decodeValue gameDecoder raw of
                Ok game ->
                    { model
                        | currentPlayer = game.currentPlayer
                        , storySegments = game.storySegments
                        , textInput = ""
                    }
                        ! []

                Err error ->
                    handleDecoderError error model


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.socket Types.PhoenixMsg


joinMainLobby : Model -> ( Model, Cmd Msg )
joinMainLobby model =
    let
        channel =
            Phoenix.Channel.init "game:main"
                |> Phoenix.Channel.onJoin handleCurrentPlayerUpdate

        ( socket, cmd ) =
            Phoenix.Socket.join channel model.socket
    in
        ( { model | socket = socket }
        , Cmd.map Types.PhoenixMsg cmd
        )


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        ( model, joinLobbyCmd ) =
            initialModel
                |> modelFromLocation location
                |> joinMainLobby

        ( routedModel, routingCmd ) =
            handleRouting model
    in
        ( routedModel, Cmd.batch [ joinLobbyCmd, routingCmd ] )
