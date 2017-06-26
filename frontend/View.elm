module View exposing (..)

import Dict
import Html exposing (..)
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
        , disabled
        , action
        , value
        )
import Html.Events
    exposing
        ( onClick
        , onInput
        , onSubmit
        , onDoubleClick
        )
import Types
    exposing
        ( Msg
        , Route
        , Player
        , Model
        )


isEmpty : String -> Bool
isEmpty =
    String.isEmpty << String.trim


initial : Model -> Html Msg
initial model =
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
                        [ class "btn btn-primary btn-lg btn-block"
                        , onClick Types.TriggerNewGame
                        , attribute "role" "button"
                        ]
                        [ text "New Game" ]
                    ]
                , div
                    [ class "col-md-6" ]
                    [ a
                        [ class "btn btn-default btn-lg btn-block"
                        , href "#join"
                        , attribute "role" "button"
                        ]
                        [ text "Join Game" ]
                    ]
                ]
            ]
        ]


navigation : Html Msg
navigation =
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


playerNameSection : String -> String -> List (Html Msg)
playerNameSection playerName inputValue =
    case playerName of
        "" ->
            [ h2 [] [ text "Player" ]
            , p [] [ text "What should we call you?" ]
            , form
                [ class "form round-container"
                , onSubmit Types.SubmitName
                , action "javascript:void(0);"
                ]
                [ div
                    [ class "form-group" ]
                    [ input
                        [ type_ "text"
                        , class "form-control input-lg"
                        , maxlength 12
                        , id "nickname"
                        , name "nickname"
                        , placeholder "Your pen name"
                        , value inputValue
                        , onInput Types.UpdateInputName
                        ]
                        []
                    , button
                        [ class "btn btn-lg btn-success btn-group-justified" ]
                        [ text "Ready ?" ]
                    ]
                ]
            ]

        _ ->
            []


lobby : Types.GameCode -> String -> String -> List Types.Player -> Html Msg
lobby gameCode playerName nameInputValue players =
    div
        [ class "container-fluid main-content" ]
        [ div
            [ class "row flex-row" ]
            [ div
                [ class "col-md-3 col-md-offset-3" ]
                [ h2 [] [ text "Game Code" ]
                , p [] [ text "Share this code with others who want to join the game." ]
                , div
                    [ class "game-code round-colored-container" ]
                    [ text gameCode ]
                , div
                    []
                    (playerNameSection playerName nameInputValue)
                ]
            , div
                [ class "col-md-3" ]
                [ h2
                    []
                    [ text "Team" ]
                , ul
                    [ class "players-list round-colored-container" ]
                    (List.map playerStatus players)
                ]
            ]
        ]


playerStatus : Player -> Html Msg
playerStatus player =
    let
        ( icon, nickname ) =
            case player.name of
                "" ->
                    ( "time", "-- You --" )

                _ ->
                    ( "ok", player.name )
    in
        li
            []
            [ span
                [ class ("glyphicon glyphicon-" ++ icon), title "Free spot" ]
                []
            , span
                [ class "nickname" ]
                [ if player.isUser && player.name /= "" then
                    strong
                        []
                        [ a
                            [ onClick Types.DeleteName
                            ]
                            [ text nickname
                            , text "  "
                            , span
                                [ class "glyphicon glyphicon-pencil"
                                ]
                                []
                            ]
                        ]
                  else
                    text nickname
                ]
            ]


join : String -> Html Msg
join newGameInput =
    div
        [ class "container-fluid main-content" ]
        [ div
            [ class "row flex-row" ]
            [ div
                [ class "col-md-2 col-md-offset-5" ]
                [ h2 [ class "text-center" ] [ text "Join a game" ]
                , form
                    [ class "form round-container"
                    , onSubmit Types.SubmitGameCode
                    , action "javascript:void(0);"
                    ]
                    [ div
                        [ class "form-group" ]
                        [ input
                            [ type_ "text"
                            , class "form-control input-lg"
                            , maxlength 12
                            , id "game-code"
                            , name "game-code"
                            , placeholder "ex. GKLPX"
                            , onInput Types.UpdateInputGameCode
                            ]
                            []
                        , button
                            [ class "btn btn-lg btn-success btn-group-justified"
                            , type_ "submit"
                            , disabled <| isEmpty newGameInput
                            ]
                            [ text "Join" ]
                        ]
                    ]
                ]
            ]
        ]


withNavigation : Html Msg -> Html Msg
withNavigation msg =
    -- Adds navigation to main app views
    div [] [ navigation, msg ]


view : Model -> Html Msg
view model =
    case model.route of
        Types.LobbyRoute gameCode ->
            withNavigation (lobby gameCode model.name model.nameInput model.players)

        Types.JoinRoute ->
            withNavigation (join model.gameCodeInput)

        _ ->
            initial model
