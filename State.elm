module State exposing (..)

import Navigation
import Types
    exposing
        ( Msg(UrlChange, SetGameState)
        , Player
        , Model
        , CurrentView
            ( CreatingGame
            , JoiningGame
            , Intro
            )
        )


initialModel : Model
initialModel =
    { name = "Anonymous"
    , gameCode = "BJKQP"
    , alertMessage = Nothing
    , nameInput = ""
    , history = []
    , currentView = Intro
    }


modelFromLocation : Model -> Navigation.Location -> Model
modelFromLocation model location =
    { model
        | history = location :: model.history
        , currentView =
            case (Debug.log "hash" location.hash) of
                "#new" ->
                    CreatingGame

                "#join" ->
                    JoiningGame

                _ ->
                    Intro
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            ( modelFromLocation model location, Cmd.none )

        SetGameState currentView ->
            ( { model | currentView = currentView }, Cmd.none )


init : Navigation.Location -> ( Model, Cmd Msg )
init location =
    ( initialModel, Cmd.none )
