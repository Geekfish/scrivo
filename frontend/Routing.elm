module Routing exposing (..)

import Navigation exposing (Location)
import UrlParser exposing (..)
import Types exposing (GameCode, Route(..))


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map HomeRoute top
        , map LobbyRoute (s "game" </> string)
        , map JoinRoute (s "join")
        ]


parseLocation : Location -> Route
parseLocation location =
    case (parseHash matchers location) of
        Just route ->
            route

        Nothing ->
            NotFoundRoute


joinPath : String
joinPath =
    "#join"


gamePath : GameCode -> String
gamePath gameCode =
    "#game/" ++ gameCode
