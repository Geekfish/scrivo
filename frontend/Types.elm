module Types exposing (..)

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
    , nameInput : String
    , route : Route
    , history : List Navigation.Location
    }


type alias GameCode =
    String


type alias Player =
    { name : String }


type Msg
    = UrlChange Navigation.Location
    | SetGameState Route
