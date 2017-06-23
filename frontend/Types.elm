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
    , gameCodeInput : String
    , nameInput : String
    , alertMessage : Maybe String
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


type
    Msg
    --
    -- Navigation
    = UrlChange Navigation.Location
    | SetGameState Route
      --
      -- Passive State Handling
    | JoinMainChannel
    | TriggerNewGame
      --
      -- Game Events
    | JoinGame GameCode
    | RegisterPlayerName String
    | UpdatePlayerName String
      --
      -- Form Submission
    | SubmitGameCode
    | SubmitName
      --
      -- Input Handling
    | UpdateInputGameCode GameCode
    | UpdateInputName String
      --
      -- Sockets
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
