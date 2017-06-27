module State exposing (..)

import Dict
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
        , list
        )
import Json.Encode
import Json.Decode
import Json.Decode exposing (int, string, float, bool, Decoder)
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
    , playerRef = ""
    , players = []
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


gameDecoder : Decoder Game
gameDecoder =
    decode Types.Game
        |> required "game_code" string


playerDecoder : Decoder Player
playerDecoder =
    decode Types.Player
        |> optional "name" string "Anonymous"
        |> required "ref" string


presenceDecoder : Decoder Presence
presenceDecoder =
    decode Types.Presence
        |> required "ref" string
        |> required "online_at" string


handleNewGameRequest : Json.Encode.Value -> Msg
handleNewGameRequest value =
    case Json.Decode.decodeValue gameDecoder value of
        Ok game ->
            Types.JoinGame game.gameCode

        Err error ->
            Types.SetGameState Types.HomeRoute


handlePlayerRegistration : Json.Encode.Value -> Msg
handlePlayerRegistration value =
    case Json.Decode.decodeValue playerDecoder value of
        Ok player ->
            Types.UpdatePlayerName player.name

        Err error ->
            Types.SetGameState Types.HomeRoute


getGameChannel : String -> String
getGameChannel =
    (++) "game:"


mainChannel : String
mainChannel =
    "game:main"


registerPlayerParams : String -> Json.Encode.Value
registerPlayerParams name =
    Json.Encode.object [ ( "name", Json.Encode.string name ) ]


handleRouting : Model -> ( Model, Cmd Msg )
handleRouting model =
    case model.route of
        Types.LobbyRoute gameCode ->
            let
                channelName =
                    getGameChannel gameCode

                channel =
                    Phoenix.Channel.init <| channelName

                ( socket, cmd ) =
                    Phoenix.Socket.join channel
                        (model.socket
                            |> Phoenix.Socket.on "presence_state" channelName Types.HandlePresenceState
                            |> Phoenix.Socket.on "presence_diff" channelName Types.HandlePresenceDiff
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



-- playersFromPresences : PresenceState Player -> List Types.Player
-- playersFromPresences newPresenceState =
--     -- I don't know if there's another way other than this crazy function.
--     --
--     -- presences : {
--     --  "ASDASDADSASDA" : {
--     --    metas : [ payload: {
--     --          , name = "Anonymous"
--     --          , ref = "ASDASDADSASDA"
--     --          , ...
--     --          }
--     --    , phx_ref = "1BFfJ0KgU90="
--     --    ]
--     --   }
--     -- }
--     newPresenceState
--         |> Dict.values
--         |> List.map (.metas >> List.head >> Maybe.map .payload)
--         |> List.filterMap identity


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

        Types.UpdatePlayerName playerName ->
            { model | name = playerName } ! []

        --
        -- Form Submission
        Types.SubmitGameCode ->
            update
                (Types.JoinGame model.gameCodeInput)
                model

        Types.SubmitName ->
            let
                push =
                    getGameChannel model.gameCode
                        |> Phoenix.Push.init "player:player"
                        |> Phoenix.Push.withPayload (registerPlayerParams model.nameInput)
                        |> Phoenix.Push.onOk handlePlayerRegistration

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

        --
        -- UI Events
        Types.TriggerNewGame ->
            let
                push =
                    Phoenix.Push.init "new:game" mainChannel
                        |> Phoenix.Push.onOk handleNewGameRequest

                ( socket, cmd ) =
                    Phoenix.Socket.push push model.socket
            in
                ( { model | socket = socket }
                , Cmd.map Types.PhoenixMsg cmd
                )

        Types.DeleteName ->
            { model | name = "" } ! []

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
                    let
                        _ =
                            Debug.log "Error" error
                    in
                        model ! []

        Types.HandlePresenceDiff raw ->
            case Json.Decode.decodeValue (presenceDiffDecoder presenceDecoder) raw of
                Ok presenceDiff ->
                    let
                        newPresenceState =
                            model.presences |> syncDiff presenceDiff
                    in
                        { model | presences = newPresenceState } ! []

                Err error ->
                    let
                        _ =
                            Debug.log "Error" error
                    in
                        model ! []


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.socket Types.PhoenixMsg


joinMainLobby : Model -> ( Model, Cmd Msg )
joinMainLobby model =
    let
        channel =
            Phoenix.Channel.init "game:main"

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
