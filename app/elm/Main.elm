module Main exposing (..)

import Html exposing (Html, button, div, text)
import Html.Events exposing (onClick)
import Svg exposing (..)
import Svg.Attributes exposing (..)


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
        ]
