module Player exposing (..)

import Dict
import Types exposing (Model, Player)


playersOnline : Model -> List Player
playersOnline model =
    Dict.values model.players
        |> List.filter (\p -> List.member p.ref (Dict.keys model.presences))
