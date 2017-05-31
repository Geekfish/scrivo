module View exposing (..)

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
        )
import Types
    exposing
        ( Msg
        , CurrentView(InLobby, JoiningGame)
        , Player
        , Model
        )


initial : Html Msg
initial =
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


lobby : Html Msg
lobby =
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
                                [ type_ "text"
                                , class "form-control input-lg"
                                , maxlength 12
                                , id "nickname"
                                , name "nickname"
                                , placeholder "Your name"
                                ]
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
                    [ playerStatus (Just { name = "MadMax15234" })
                    , playerStatus (Just { name = "Popotin" })
                    , playerStatus Nothing
                    ]
                ]
            ]
        ]


playerStatus : Maybe Player -> Html Msg
playerStatus player =
    let
        ( icon, nickname ) =
            case player of
                Just player ->
                    ( "ok", player.name )

                Nothing ->
                    ( "pencil", "-- Free spot --" )
    in
        li
            []
            [ span
                [ class ("glyphicon glyphicon-" ++ icon), title "Free spot" ]
                []
            , span
                [ class "nickname" ]
                [ text nickname ]
            ]


join : Html Msg
join =
    div
        [ class "container-fluid vertical-center" ]
        [ h1 [] [ text "Join Game" ] ]


withNavigation : Html Msg -> Html Msg
withNavigation msg =
    -- Adds navigation to main app views
    div [] [ navigation, msg ]


view : Model -> Html Msg
view model =
    case model.currentView of
        InLobby ->
            withNavigation lobby

        JoiningGame ->
            withNavigation join

        _ ->
            initial
