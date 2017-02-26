module Main exposing (..)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Svg exposing (..)
import Svg.Attributes exposing (..)


roundRect : Html.Html msg
roundRect =
    svg
        [ width "120", height "120", viewBox "0 0 120 120" ]
        [ rect [ x "10", y "10", width "100", height "100", rx "15", ry "15" ] [] ]


main =
    Html.beginnerProgram { model = model, view = view, update = update }



-- MODEL


type alias Model =
    Int


model : Model
model =
    0



-- UPDATE


type Msg
    = Increment
    | Decrement


update : Msg -> Model -> Model
update msg model =
    case msg of
        Increment ->
            model + 1

        Decrement ->
            model - 1



-- VIEW


view : Model -> Html Msg
view model =
    div []
        [ button [ onClick Decrement ] [ Html.text "-" ]
        , div [] [ Html.text (toString model) ]
        , button [ onClick Increment ] [ Html.text "+" ]
        , div [] [ roundRect ]
        ]
