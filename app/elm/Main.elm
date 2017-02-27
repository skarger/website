module Main exposing (..)

import Html exposing (Html, button, div, text, table, thead, tbody, th, tr, td)
import Html.Attributes exposing (class)
import Html.Events exposing (onClick)


main =
    Html.beginnerProgram { model = model, view = view, update = update }



-- MODEL


type Score
    = Touchdown
    | ExtraPoint
    | FieldGoal


type alias Model =
    { scores : List Score }


model : Model
model =
    { scores = []
    }



-- UPDATE


type Msg
    = Reset
    | AddTouchdown
    | AddExtraPoint
    | AddFieldGoal


update : Msg -> Model -> Model
update msg model =
    case msg of
        Reset ->
            { model | scores = [] }

        AddTouchdown ->
            { model | scores = model.scores ++ [ Touchdown ] }

        AddExtraPoint ->
            { model | scores = model.scores ++ [ ExtraPoint ] }

        AddFieldGoal ->
            { model | scores = model.scores ++ [ FieldGoal ] }


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
    div []
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
