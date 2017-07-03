module Types exposing (..)

import Dict exposing (Dict)
import Json.Encode
import Phoenix.Socket
import Phoenix.Presence
    exposing
        ( PresenceState
        , syncState
        , syncDiff
        , presenceStateDecoder
        , presenceDiffDecoder
        )
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
    , playerRef : String
    , players : Players
    , inProgress : Bool
    , alertMessage : Maybe String
    , route : Route
    , history : List Navigation.Location
    , socket : Phoenix.Socket.Socket Msg
    , presences : PresenceState Presence
    }


type alias GameCode =
    String


type alias Game =
    { gameCode : GameCode
    , inProgress : Bool
    }


type alias GameAndPlayers =
    { gameCode : GameCode
    , players : Players
    }


type alias Presence =
    { ref : String
    , online_at : String
    }


type alias Players =
    Dict String Player


type alias Player =
    { ref : String
    , name : String
    }


type
    Msg
    --
    -- Navigation
    = UrlChange Navigation.Location
    | SetGameState Route
      -- Alerts
    | DisplayError String
    | CloseAlert
      --
      -- Passive State Handling
    | JoinMainChannel
      --
      -- Game Events
    | JoinGame GameCode
    | UpdatePlayer Player
      --
      -- Form Submission
    | SubmitGameCode
    | SubmitName
      --
      -- Input Handling
    | UpdateInputGameCode GameCode
    | UpdateInputName String
      --
      -- Other UI Events
    | TriggerNewGame
    | DeleteName
    | StartGame
      --
      -- Sockets
    | PhoenixMsg (Phoenix.Socket.Msg Msg)
    | HandlePresenceState Json.Encode.Value
    | HandlePresenceDiff Json.Encode.Value
    | HandlePlayerUpdate Json.Encode.Value
    | HandleGameJoin Json.Encode.Value
    | HandleGameStart Json.Encode.Value
