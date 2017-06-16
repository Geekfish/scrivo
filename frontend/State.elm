module State exposing (..)

import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push
import Json.Encode
import Json.Decode
import Debug
import Navigation
import Routing exposing (parseLocation)
import Types
    exposing
        ( Msg
        , Player
        , Model
        , Route
        )


initialModel : Model
initialModel =
    { name = "Anonymous"
    , gameCode = ""
    , alertMessage = Nothing
    , nameInput = ""
    , history = []
    , route = Types.HomeRoute
    , socket =
        Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
            |> Phoenix.Socket.withDebug
    }


modelFromLocation : Navigation.Location -> Model -> Model
modelFromLocation location model =
    { model
        | history = location :: model.history
        , route = parseLocation location
    }


newGameDecoder : Json.Decode.Decoder Types.Game
newGameDecoder =
    Json.Decode.map Types.Game
        (Json.Decode.field "game_code" Json.Decode.string)


handleNewGame : Json.Encode.Value -> Msg
handleNewGame value =
    case Json.Decode.decodeValue newGameDecoder value of
        Ok game ->
            let
                game_code =
                    Debug.log game.game_code
            in
                Types.SetGameState (Types.LobbyRoute game.game_code)

        Err error ->
            Types.SetGameState Types.HomeRoute


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Types.UrlChange location ->
            ( modelFromLocation location model, Cmd.none )

        Types.SetGameState route ->
            ( { model | route = route }, Cmd.none )

        Types.JoinGameLobby ->
            let
                channel =
                    Phoenix.Channel.init "game:lobby"

                ( socket, cmd ) =
                    Phoenix.Socket.join channel model.socket
            in
                ( { model | socket = socket }
                , Cmd.map Types.PhoenixMsg cmd
                )

        Types.StartGame ->
            let
                push =
                    Phoenix.Push.init "new:game" "game:lobby"

                ( socket, cmd ) =
                    Phoenix.Socket.push push model.socket
            in
                ( { model | socket = socket }
                , Cmd.map Types.PhoenixMsg cmd
                )

        Types.PhoenixMsg msg ->
            let
                ( socket, cmd ) =
                    Phoenix.Socket.update msg model.socket
            in
                ( { model | socket = socket }
                , Cmd.map Types.PhoenixMsg cmd
                )


subscriptions : Model -> Sub Msg
subscriptions model =
    Phoenix.Socket.listen model.socket Types.PhoenixMsg


joinMainLobby : Model -> ( Model, Cmd Msg )
joinMainLobby model =
    let
        channel =
            Phoenix.Channel.init "game:lobby"

        ( socket, cmd ) =
            Phoenix.Socket.join channel model.socket
    in
        ( { model | socket = socket }
        , Cmd.map Types.PhoenixMsg cmd
        )


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    let
        ( model, cmd ) =
            initialModel
                |> modelFromLocation location
                |> joinMainLobby
    in
        ( model, cmd )
