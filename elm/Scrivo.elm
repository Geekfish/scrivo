module Scrivo exposing (..)

import Navigation
import Types
    exposing
        ( Msg(UrlChange)
        , Model
        )
import State exposing (init, update)
import View exposing (view)


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { init = init
        , view = view
        , update = update
        , subscriptions = (\_ -> Sub.none)
        }
