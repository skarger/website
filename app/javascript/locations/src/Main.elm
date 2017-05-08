module Main exposing (..)

import Html exposing (Html, button, h3, div, input, text, ol, li)
import Html.Events exposing (onInput)
import Html.Attributes exposing (class, id, placeholder)
import String exposing (join, split, lines, indices, trim)
import Dict
import Uuid exposing (uuidGenerator)
import Models exposing (..)
import Messages exposing (..)
import Stops.UrlParser exposing (parseStops)
import Stops.Stops as Stops
import Stops.Geocoder as StopsGeocoder
import Stops.Models exposing (StopInput(..), Stop(..), extractStopId, toCompleteStop)
import Stops.View as StopsView
import Stops.AreaValidator as StopAreaValidator
import Stops.Server exposing (serializeStopAreas, saveStopsToServer, noContentResponse)
import Random.Pcg exposing (Seed, initialSeed, step)
import GoogleMaps


type alias Flags =
    { waiting : String
    , randomInt : Int
    }


main : Program Flags Model Msg
main =
    Html.programWithFlags
        { init = init
        , subscriptions = subscriptions
        , view = view
        , update = update
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( emptyModel flags.waiting (initialSeed flags.randomInt), Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        EnterUrl userEnteredContent ->
            let
                url =
                    trim userEnteredContent
            in
                case parseStops model url of
                    Ok ( newSeed, parsedStops ) ->
                        let
                            newStopAreaIndex =
                                model.stopAreaIndex + List.length parsedStops

                            newStopAreas =
                                Dict.fromList <|
                                    List.indexedMap
                                        (\i ps -> ( i + model.stopAreaIndex, Stops.initializeStopArea ps ))
                                        parsedStops
                        in
                            ( { model
                                | url = url
                                , stopAreas = Dict.union model.stopAreas newStopAreas
                                , error = ""
                                , stopAreaIndex = newStopAreaIndex
                                , currentSeed = newSeed
                              }
                            , StopsGeocoder.geocodeStops newStopAreas
                            )

                    Err error ->
                        ( { model
                            | url = url
                            , error = error
                          }
                        , Cmd.none
                        )

        StopsGeocoderResult stopAreaId stopArea res ->
            StopsGeocoder.handleGeocodingResponse model stopAreaId stopArea res

        RetryGeocoding stopAreaId ->
            ( model
            , StopsGeocoder.geocodeStops
                (Dict.filter (\id _ -> id == stopAreaId) model.stopAreas)
            )

        NameChanged stopAreaId stopId name ->
            let
                updatedModel =
                    Stops.updateStopName name model stopAreaId stopId
            in
                ( StopAreaValidator.validate updatedModel stopAreaId
                , GoogleMaps.updateMarkerTitle stopId name
                )

        DoubleClickMap coordinates ->
            let
                drawn =
                    True

                stopInput =
                    PointFromMap coordinates.id
                        coordinates.latitude
                        coordinates.longitude

                key =
                    model.stopAreaIndex

                stopArea =
                    Stops.initializeStopArea stopInput
            in
                ( { model
                    | stopAreas =
                        Dict.insert key stopArea model.stopAreas
                    , stopAreaIndex = key + 1
                  }
                , StopsGeocoder.geocodeStops (Dict.singleton key stopArea)
                )

        PossibleDuplicateStops stopAreaId result ->
            case result of
                Ok stopList ->
                    let
                        updatedModel =
                            Stops.appendPossibleDuplicates stopList model stopAreaId
                    in
                        ( StopAreaValidator.validate updatedModel stopAreaId
                        , Stops.drawPossibleDuplicates stopList
                        )

                Err error ->
                    ( model, Cmd.none )

        FocusStop stopId ->
            ( model, GoogleMaps.focusMarker stopId )

        UnfocusStop stopId ->
            ( model, GoogleMaps.unfocusMarker stopId )

        ChooseStop stopAreaId chosenStopId ->
            let
                updatedModel =
                    Stops.updateStopChosen model stopAreaId chosenStopId
            in
                ( StopAreaValidator.validate updatedModel stopAreaId
                , Stops.refocusStopArea updatedModel stopAreaId chosenStopId
                )

        RemoveStopEntry stopAreaId ->
            Stops.removeStopArea model stopAreaId

        ClearStops ->
            let
                stopAreaStops sa =
                    Dict.values sa.stops

                stops =
                    Dict.values model.stopAreas
                        |> List.concatMap stopAreaStops
            in
                ( emptyModel model.waiting
                    (model.currentSeed |> step uuidGenerator |> Tuple.second)
                , GoogleMaps.clearMarkers stops
                )

        SaveStops ->
            let
                -- assumes that stop areas have been validated before this message
                requestBody =
                    serializeStopAreas model.stopAreas
            in
                ( { model | saveStatus = Saving }, saveStopsToServer requestBody )

        SaveStopsResult result ->
            if noContentResponse result then
                ( { model | saveStatus = Success }, Cmd.none )
            else
                case result of
                    Ok response ->
                        Debug.log
                            ("Success but unexpected response: " ++ toString response)
                            ( { model | saveStatus = Success }, Cmd.none )

                    Err error ->
                        Debug.log
                            ("Error response: " ++ toString error)
                            ( { model | saveStatus = Failure }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    GoogleMaps.doubleClickMap DoubleClickMap


view : Model -> Html Msg
view model =
    div [ id "main" ]
        [ h3 [ id "main-heading" ] [ text "Locations Entry" ]
        , div [ class "urls-section" ]
            [ div
                [ class "ui input url-entry" ]
                [ input
                    [ onInput EnterUrl
                    , placeholder "Enter Google Maps Directions Url"
                    ]
                    []
                ]
            ]
        , div [ id "errors" ] [ text (model.error) ]
        , div [] []
        , div [ class "ui hidden divider" ] []
        , div [ id "stops-view" ] (StopsView.view model)
        ]
