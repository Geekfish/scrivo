module Player exposing (..)

import Dict
import Types exposing (Model, Player)


minNumPlayers : Int
minNumPlayers =
    2


playersOnline : Model -> List Player
playersOnline model =
    Dict.values model.players
        |> List.filter (\p -> List.member p.ref (Dict.keys model.presences))


isReady : Player -> Bool
isReady player =
    player.name /= ""


minNumPlayersReady : List Player -> Bool
minNumPlayersReady players =
    players
        |> List.filter isReady
        |> List.length
        |> (<=) minNumPlayers
