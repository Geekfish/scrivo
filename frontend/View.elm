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
import Player exposing (playersOnline, isReady, minNumPlayersReady)
import Types
    exposing
        ( Msg
        , Route
        , Player
        , Model
        , StorySegment
        )


isEmpty : String -> Bool
isEmpty =
    String.isEmpty << String.trim


initial : Model -> Html Msg
initial model =
    div []
        [ alertBox model.alertMessage
        , div [ class "container-fluid vertical-center" ]
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


lobby : Model -> Html Msg
lobby model =
    let
        players =
            playersOnline model
    in
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
                        [ text model.gameCode ]
                    , div
                        []
                        (playerNameSection model.name model.nameInput)
                    ]
                , div
                    [ class "col-md-3" ]
                    [ h2
                        []
                        [ text "Team" ]
                    , ul
                        [ class "players-list round-colored-container" ]
                        (players |> List.map (playerStatus model.playerRef))
                    ]
                , div
                    [ class "col-md-3 col-md-offset-4 start-game" ]
                    [ if minNumPlayersReady players then
                        (a
                            [ class "btn btn-primary btn-lg btn-block"
                            , onClick Types.StartGame
                            ]
                            [ text "Start" ]
                        )
                      else
                        (p [] [ text "Waiting for more players to get ready..." ])
                    ]
                ]
            ]


playerStatus : String -> Player -> Html Msg
playerStatus currentRef player =
    let
        isCurrent =
            player.ref == currentRef

        ( icon, nickname ) =
            if isReady (player) then
                ( "ok", player.name )
            else
                ( "time", "Anonymous" )
    in
        li
            []
            [ span
                [ class ("glyphicon glyphicon-" ++ icon), title "Free spot" ]
                []
            , span
                [ class "nickname" ]
                [ if isCurrent && isReady player then
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


isCurrentPlayer : Model -> Bool
isCurrentPlayer model =
    case model.currentPlayer of
        Just currentPlayerRef ->
            currentPlayerRef == model.playerRef

        _ ->
            False


currentPlayerInputOrProgress : Model -> Html Msg
currentPlayerInputOrProgress model =
    if isCurrentPlayer model then
        div
            [ class "col-md-6 col-md-offset-3" ]
            [ form
                [ class "form round-container"
                , onSubmit Types.SubmitStorySegment
                , action "javascript:void(0);"
                ]
                [ textarea
                    [ placeholder "Once upon a time..."
                    , class "idented"
                      -- TODO: This max length is not based on anything,
                      -- find a more reasonable limit and display to user.
                    , maxlength 400
                    , onInput Types.UpdateInputText
                    ]
                    []
                , button
                    [ class "btn btn-lg btn-success btn-group-justified"
                    , type_ "submit"
                    , disabled <| isEmpty model.textInput
                    ]
                    [ text "This really happened" ]
                ]
            ]
    else
        div
            [ class "col-md-6 col-md-offset-3 round-colored-container" ]
            [ p [ class "idented blur" ] [ text model.textInput ] ]


renderWords : List String -> List Int -> List (Html Msg)
renderWords words visibleWords =
    let
        render index word =
            if (List.member (index + 1) visibleWords) then
                span [] [ text word ]
            else
                span [ class "blur" ] [ text word ]
    in
        List.indexedMap render words


renderSegment : StorySegment -> Html Msg
renderSegment storySegment =
    -- TODO: If it's your segment, show all of it
    let
        words =
            String.split " " storySegment.text
    in
        div
            [ class "col-md-6 col-md-offset-3 round-colored-container" ]
            [ p
                [ class "idented" ]
                (renderWords words storySegment.visibleWords)
            ]


gameInProgress : Model -> Html Msg
gameInProgress model =
    div
        [ class "container-fluid main-content" ]
        [ div
            [ class "row flex-row" ]
            ([ div
                [ class "col-md-2 col-md-offset-5" ]
                -- TODO: input real random title
                [ h2 [ class "text-center" ] [ text model.title ] ]
             ]
                ++ (List.map renderSegment model.storySegments)
                ++ [ currentPlayerInputOrProgress model ]
            )
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


game : Html msg
game =
    div [] [ text "The game" ]


alertBox : Maybe String -> Html Msg
alertBox message =
    case message of
        Just message ->
            div
                [ class "alert alert-warning alert-dismissable" ]
                [ a
                    [ href "#"
                    , class "close"
                    , attribute "aria-label" "close"
                    , onClick Types.CloseAlert
                    ]
                    [ text "×" ]
                , strong
                    []
                    [ text message ]
                ]

        Nothing ->
            text ""


withNavigation : Maybe String -> Html Msg -> Html Msg
withNavigation message msg =
    -- Adds navigation to main app views
    div [] [ navigation, alertBox message, msg ]


view : Model -> Html Msg
view model =
    case model.route of
        Types.LobbyRoute gameCode ->
            let
                gameView =
                    if model.inProgress then
                        gameInProgress
                    else
                        lobby
            in
                withNavigation model.alertMessage (gameView model)

        Types.JoinRoute ->
            withNavigation model.alertMessage (join model.gameCodeInput)

        _ ->
            initial model
