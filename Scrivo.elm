module Scrivo exposing (..)

import Html exposing (..)
import Debug
import Html.Attributes
    exposing
        ( class
        , href
        , attribute
        , type_
        , maxlength
        , id
        , hidden
        , title
        , placeholder
        , name
        )
import Html.Events exposing (onClick)
import Navigation exposing (Location)


type GameState
    = Intro
    | CreatingGame
    | JoiningGame
    | Playing


type alias Model =
    { name : String
    , gameCode : String
    , alertMessage : Maybe String
    , nameInput : String
    , gameState : GameState
    , history : List Navigation.Location
    }


type Msg
    = UrlChange Navigation.Location
    | SetGameState GameState


initialModel : Model
initialModel =
    { name = "Anonymous"
    , gameCode = "BJKQP"
    , alertMessage = Nothing
    , nameInput = ""
    , history = []
    , gameState = Intro
    }


viewInitial : Html Msg
viewInitial =
    div [ class "container-fluid vertical-center" ]
        [ div
            [ class "start col-md-6 col-md-offset-3" ]
            [ h1 [] [ text "Scrivo", sup [] [ text "beta" ] ]
            , p [] [ text "Collaborative gaming meets writing improvisation" ]
            , div
                [ class "row" ]
                [ div
                    [ class "col-md-6" ]
                    [ a
                        [ class "btn btn-primary btn-lg"
                        , href "#new"
                        , attribute "role" "button"
                        ]
                        [ text "New Game" ]
                    ]
                , div
                    [ class "col-md-6" ]
                    [ a
                        [ class "btn btn-default btn-lg"
                        , href "#join"
                        , attribute "role" "button"
                        ]
                        [ text "Join an existing game" ]
                    ]
                ]
            ]
        ]


viewNavigation : Html Msg
viewNavigation =
    nav
        [ class "navbar navbar-default navbar-fixed-top" ]
        [ div
            [ class "container-fluid" ]
            [ div
                [ class "navbar-header" ]
                [ a
                    [ class "navbar-brand", href "#" ]
                    [ text "Scrivo"
                    , sup [] [ text "beta" ]
                    ]
                ]
            ]
        ]


viewGameLobby : Html Msg
viewGameLobby =
    div
        [ class "container-fluid main-content" ]
        [ div
            [ class "row flex-row" ]
            [ div
                [ class "col-md-3 col-md-offset-3" ]
                [ h2 [] [ text "Game Code" ]
                , div
                    [ class "game-code round-colored-container" ]
                    [ text "BJKWPTQ" ]
                , div
                    []
                    [ h2
                        []
                        [ text "Profile" ]
                    , form
                        [ class "form round-container" ]
                        [ div
                            [ class "form-group" ]
                            [ input
                                [ type_ "text", class "form-control input-lg", maxlength 12, id "nickname", name "nickname", placeholder "Your name" ]
                                []
                            , button
                                [ class "btn btn-lg btn-success btn-group-justified" ]
                                [ text "Ready ?" ]
                            ]
                        ]
                    ]
                ]
            , div
                [ class "col-md-3" ]
                [ h2
                    []
                    [ text "Players Joined" ]
                , ul
                    [ class "players-list round-colored-container" ]
                    [ li
                        []
                        [ span
                            [ class "glyphicon glyphicon-ok", title "Ready!" ]
                            []
                        , span
                            [ class "nickname" ]
                            [ text "Alpaca15234" ]
                        ]
                    , li
                        []
                        [ span
                            [ class "glyphicon glyphicon-time", title "Not ready" ]
                            []
                        , span
                            [ class "nickname" ]
                            [ text "Unicorn6273" ]
                        ]
                    , li
                        []
                        [ span
                            [ class "glyphicon glyphicon-ok", title "Ready!" ]
                            []
                        , span
                            [ class "nickname" ]
                            [ text "Hippo65228" ]
                        ]
                    , li
                        []
                        [ span
                            [ class "glyphicon glyphicon-pencil", title "Free spot" ]
                            []
                        , span
                            [ class "nickname" ]
                            [ text "-- Free spot --" ]
                        ]
                    ]
                ]
            ]
        ]


appView : Html Msg -> Html Msg
appView msg =
    -- Add navigation to main app views
    div [] [ viewNavigation, msg ]


view : Model -> Html Msg
view model =
    case model.gameState of
        CreatingGame ->
            appView viewGameLobby

        JoiningGame ->
            appView
                (div
                    [ class "container-fluid vertical-center" ]
                    [ h1 [] [ text "Join Game" ] ]
                )

        _ ->
            viewInitial


modelFromLocation : Model -> Navigation.Location -> Model
modelFromLocation model location =
    { model
        | history = location :: model.history
        , gameState =
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

        SetGameState gameState ->
            ( { model | gameState = gameState }, Cmd.none )


main : Program Never Model Msg
main =
    Navigation.program UrlChange
        { init = (\location -> ( initialModel, Cmd.none ))
        , view = view
        , update = update
        , subscriptions = (\_ -> Sub.none)
        }
