module Types exposing (..)

import Navigation exposing (Location)


type CurrentView
    = Intro
    | InLobby
    | JoiningGame
    | Playing


type alias Model =
    { name : String
    , gameCode : String
    , alertMessage : Maybe String
    , nameInput : String
    , currentView : CurrentView
    , history : List Navigation.Location
    }


type alias Player =
    { name : String }


type Msg
    = UrlChange Navigation.Location
    | SetGameState CurrentView
