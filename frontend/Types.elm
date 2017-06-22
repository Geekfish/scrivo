module Types exposing (..)

import Phoenix.Socket
import Navigation exposing (Location)


type Route
    = HomeRoute
    | LobbyRoute GameCode
    | JoinRoute
    | NotFoundRoute


type alias Model =
    { name : String
    , gameCode : String
    , alertMessage : Maybe String
    , gameCodeInput : String
    , nameInput : String
    , route : Route
    , history : List Navigation.Location
    , socket : Phoenix.Socket.Socket Msg
    }


type alias GameCode =
    String


type alias Game =
    { gameCode : GameCode
    }


type alias Player =
    { name : String }


type Msg
    = UrlChange Navigation.Location
    | SetGameState Route
    | JoinMainChannel
    | JoinGameFromForm
    | TriggerNewGame
    | HandleNewGameCode GameCode
    | UpdateGameCodeInput GameCode
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
