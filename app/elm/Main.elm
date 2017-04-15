module Main exposing (..)

import Html
    exposing
        ( Html
        , h1
        , button
        , div
        , span
        , text
        , pre
        , code
        , a
        , ul
        , li
        , p
        , table
        , thead
        , tbody
        , th
        , tr
        , td
        )
import Html.Attributes exposing (id, class, href, attribute)
import Html.Events exposing (onClick)
import Navigation
import Ports


main =
    Navigation.program UrlChange
        { init = init
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


init : Navigation.Location -> ( Model, Cmd msg )
init location =
    ( Model [ location ] [], Ports.highlightCode Ports.emptyOptions )



-- MODEL


type Score
    = Touchdown
    | ExtraPoint
    | FieldGoal


type alias Model =
    { history : List Navigation.Location
    , scores : List Score
    }


model : Model
model =
    { history = []
    , scores = []
    }



-- UPDATE


type Msg
    = UrlChange Navigation.Location
    | Reset
    | AddTouchdown
    | AddExtraPoint
    | AddFieldGoal


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UrlChange location ->
            let
                updatedHistory =
                    location :: model.history
            in
                ( { model | history = updatedHistory }, Ports.highlightCode Ports.emptyOptions )

        Reset ->
            ( { model | scores = [] }, Cmd.none )

        AddTouchdown ->
            ( { model | scores = model.scores ++ [ Touchdown ] }, Cmd.none )

        AddExtraPoint ->
            ( { model | scores = model.scores ++ [ ExtraPoint ] }, Cmd.none )

        AddFieldGoal ->
            ( { model | scores = model.scores ++ [ FieldGoal ] }, Cmd.none )


points : Score -> Int
points s =
    case s of
        Touchdown ->
            6

        ExtraPoint ->
            1

        FieldGoal ->
            3


reaction : Score -> String
reaction =
    always "OH YEAH!"



-- VIEW


row : Score -> Html Msg
row score =
    [ scoreItem score, reactionItem score ]
        |> tr []


scoreItem : Score -> Html Msg
scoreItem score =
    points score
        |> toString
        |> text
        |> List.singleton
        |> td []


reactionItem : Score -> Html Msg
reactionItem score =
    reaction score
        |> text
        |> List.singleton
        |> td []


view : Model -> Html Msg
view model =
    div [ id "main-grid" ] <|
        List.append
            [ div [ class "header" ] [ h1 [] [ text "Elm Package Demos" ] ]
            , div [ class "sidebar" ] viewSidebar
            ]
            (case List.head model.history of
                Just location ->
                    viewContent model (location.pathname ++ location.hash)

                Nothing ->
                    viewHome
            )


viewSidebar : List (Html Msg)
viewSidebar =
    [ a [ href "/elm#about", attribute "data-turbolinks" "false" ] [ text "About" ]
    , ul [ class "package-list" ]
        [ li []
            [ text "Core"
            , ul [ class "module-list" ]
                [ li []
                    [ text "Basics"
                    , li
                        []
                        [ ul [ class "function-list" ]
                            [ li [] [ viewLink "always" ]
                            ]
                        ]
                    ]
                ]
            ]
        ]
    ]


viewContent : Model -> String -> List (Html Msg)
viewContent model location =
    case location of
        "/elm#always" ->
            viewAlways model

        otherwise ->
            viewHome


viewHome : List (Html Msg)
viewHome =
    [ div [ class "content" ]
        [ span [ class "about" ]
            [ p []
                [ text """
        Choose from the left sidebar to view demos of various functions from the Elm core libraries.
        """
                ]
            , p []
                [ text """
        This demo area is an Elm SPA itself, using the
        """
                , a [ href "http://package.elm-lang.org/packages/elm-lang/navigation/latest" ] [ text "Navigation" ]
                , text " package for routing."
                ]
            ]
        ]
    ]


viewAlways : Model -> List (Html Msg)
viewAlways model =
    [ div [ class "content" ]
        [ viewCode
        ]
    , div [ class "right-content" ]
        [ button [ class "demo", onClick Reset ] [ text "Reset" ]
        , button [ class "demo", onClick AddTouchdown ] [ text "Touchdown" ]
        , button [ class "demo", onClick AddExtraPoint ] [ text "Extra Point" ]
        , button [ class "demo", onClick AddFieldGoal ] [ text "Field Goal" ]
        , table []
            [ thead []
                [ th [] [ text "Points" ]
                , th [] [ text "Reaction" ]
                ]
            , tbody [] (List.map row model.scores)
            ]
        ]
    ]


viewCode : Html msg
viewCode =
    pre []
        [ code
            []
            [ span [ class "code-block" ]
                [ text """type Score
        = Touchdown
        | ExtraPoint
        | FieldGoal


points : Score -> Int
points s =
        case s of
            Touchdown ->
                6

            ExtraPoint ->
                1

            FieldGoal ->
                3


reaction : Score -> String
reaction =
        always "OH YEAH!"
                """ ]
            ]
        ]


viewLink : String -> Html msg
viewLink name =
    li [] [ a [ href ("#" ++ name), attribute "data-turbolinks" "false" ] [ text name ] ]


viewLocation : Navigation.Location -> Html msg
viewLocation location =
    li [] [ text (location.pathname ++ location.hash) ]
