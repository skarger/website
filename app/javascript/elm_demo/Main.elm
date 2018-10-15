module Main exposing (Model, Msg(..), Score(..), init, main, onUrlChange, onUrlRequest, points, reaction, reactionItem, row, scoreItem, update, view, viewAlways, viewCode, viewContent, viewHome, viewLink, viewSidebar)

import Browser exposing (UrlRequest(..))
import Browser.Navigation
import Html
    exposing
        ( Html
        , a
        , button
        , code
        , div
        , h1
        , li
        , p
        , pre
        , span
        , table
        , tbody
        , td
        , text
        , th
        , thead
        , tr
        , ul
        )
import Html.Attributes exposing (attribute, class, href, id)
import Html.Events exposing (onClick)
import Ports
import Url exposing (Url)


namespace : String
namespace =
    "elm_demo"


pageTitle : String
pageTitle =
    "Website"


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , view = view
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = onUrlRequest
        , onUrlChange = onUrlChange
        }


init : () -> Url -> Browser.Navigation.Key -> ( Model, Cmd msg )
init flags url key =
    ( Model [] url key, Ports.highlightCode Ports.emptyOptions )


onUrlRequest : Browser.UrlRequest -> Msg
onUrlRequest request =
    ClickedLink request


onUrlChange : Url -> Msg
onUrlChange url =
    UrlChange url



-- MODEL


type Score
    = Touchdown
    | ExtraPoint
    | FieldGoal


type alias Model =
    { scores : List Score
    , currentUrl : Url
    , key : Browser.Navigation.Key
    }



-- UPDATE


type Msg
    = ClickedLink Browser.UrlRequest
    | UrlChange Url
    | Reset
    | AddTouchdown
    | AddExtraPoint
    | AddFieldGoal


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedLink urlRequest ->
            case urlRequest of
                Internal url ->
                    if String.contains namespace <| Url.toString url then
                        ( model, Browser.Navigation.pushUrl model.key (Url.toString url) )

                    else
                        ( model, Browser.Navigation.load <| Url.toString url )

                External url ->
                    ( model, Browser.Navigation.load url )

        UrlChange url ->
            ( { model | currentUrl = url }, Ports.highlightCode Ports.emptyOptions )

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
        |> String.fromInt
        |> text
        |> List.singleton
        |> td []


reactionItem : Score -> Html Msg
reactionItem score =
    reaction score
        |> text
        |> List.singleton
        |> td []


view : Model -> Browser.Document Msg
view model =
    let
        mainBody =
            List.append
                [ div [ class "header" ] [ h1 [] [ text "Elm Package Demos" ] ]
                , div [ class "sidebar" ] viewSidebar
                ]
                (case model.currentUrl.fragment of
                    Just fragment ->
                        viewContent model fragment

                    Nothing ->
                        viewHome
                )
    in
    { title = pageTitle
    , body = [ viewNav, div [ id "main-grid" ] mainBody ]
    }


viewNav : Html Msg
viewNav =
    div [ class "nav_container" ]
        [ ul [ class "nav_list" ]
            [ li [ class "" ] [ a [ class "nav_list", href "/" ] [ text "/" ] ]
            , li [ class "" ] [ a [ class "nav_list", href "/about" ] [ text "ABOUT" ] ]
            , li [ class "" ] [ a [ class "nav_list", href "/login" ] [ text "LOG IN" ] ]
            ]
        ]


viewSidebar : List (Html Msg)
viewSidebar =
    [ a [ href "/elm_demo#about", attribute "data-turbolinks" "false" ] [ text "About" ]
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
        "always" ->
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
                , a [ href "https://package.elm-lang.org/packages/elm/browser/latest/Browser-Navigation" ] [ text "Browser.Navigation" ]
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
