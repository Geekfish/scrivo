module State exposing (..)

import Phoenix.Socket
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
    , gameCode = "BJKQP"
    , alertMessage = Nothing
    , nameInput = ""
    , history = []
    , route = Types.HomeRoute
    , socket = Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
    }


modelFromLocation : Model -> Navigation.Location -> Model
modelFromLocation model location =
    { model
        | history = location :: model.history
        , route = parseLocation location
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Types.UrlChange location ->
            ( modelFromLocation model location, Cmd.none )

        Types.SetGameState route ->
            ( { model | route = route }, Cmd.none )

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


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( modelFromLocation initialModel location, Cmd.none )
