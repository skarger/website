module Main exposing (..)

import Html exposing (Html, button, h3, div, input, text, ol, li)
import Html.Events exposing (onInput)
import Html.Attributes exposing (class, id, placeholder)
import String exposing (join, split, lines, indices, trim)
import Dict
import Uuid exposing (uuidGenerator)
import Models exposing (..)
import Messages exposing (..)
import MessageHandlers exposing (..)
import Locations.UrlParser exposing (parseLocations)
import Locations.Locations as Locations
import Locations.Geocoder as LocationsGeocoder
import Locations.View as LocationsView
import Locations.AreaValidator as LocationAreaValidator
import Locations.Server exposing (serializeLocations, saveLocationsToServer, noContentResponse)
import Random.Pcg exposing (initialSeed, step)
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
                parseLocations model url |> integrateParsedLocations model url

        LocationsGeocoderResult locationAreaId locationArea res ->
            LocationsGeocoder.handleGeocodingResponse model locationAreaId locationArea res

        RetryGeocoding locationAreaId ->
            ( model
            , LocationsGeocoder.geocodeLocations
                (Dict.filter (\id _ -> id == locationAreaId) model.locationAreas)
            )

        NameChanged locationAreaId locationId name ->
            let
                updatedModel =
                    Locations.updateLocationName name model locationAreaId locationId
            in
                ( LocationAreaValidator.validate updatedModel locationAreaId
                , GoogleMaps.updateMarkerTitle locationId name
                )

        DoubleClickMap coordinates ->
            integrateDoubleClickLocation model coordinates

        PossibleDuplicateLocations locationAreaId result ->
            case result of
                Ok locationList ->
                    let
                        updatedModel =
                            Locations.appendPossibleDuplicates locationList model locationAreaId
                    in
                        ( LocationAreaValidator.validate updatedModel locationAreaId
                        , Locations.drawPossibleDuplicates locationList
                        )

                Err error ->
                    ( model, Cmd.none )

        FocusLocation locationId ->
            ( model, GoogleMaps.focusMarker locationId )

        UnfocusLocation locationId ->
            ( model, GoogleMaps.unfocusMarker locationId )

        ChooseLocation locationAreaId chosenLocationId ->
            let
                updatedModel =
                    Locations.updateLocationChosen model locationAreaId chosenLocationId
            in
                ( LocationAreaValidator.validate updatedModel locationAreaId
                , Locations.refocusLocationArea updatedModel locationAreaId chosenLocationId
                )

        RemoveLocationEntry locationAreaId ->
            Locations.removeLocationArea model locationAreaId

        ClearLocations ->
            let
                locationAreaLocations sa =
                    Dict.values sa.locations

                locations =
                    Dict.values model.locationAreas
                        |> List.concatMap locationAreaLocations
            in
                ( emptyModel model.waiting
                    (model.currentSeed |> step uuidGenerator |> Tuple.second)
                , GoogleMaps.clearMarkers locations
                )

        SaveLocations ->
            let
                -- assumes that location areas have been validated before this message
                requestBody =
                    serializeLocations <| Locations.chosenNewLocations model.locationAreas
            in
                ( { model | saveStatus = Saving }, saveLocationsToServer requestBody )

        SaveLocationsResult result ->
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
        , div [ class "input-intro" ]
            [ div [ class "urls-section" ]
                [ div
                    [ class "ui input url-entry" ]
                    [ input
                        [ onInput EnterUrl
                        , placeholder "Enter Google Maps Directions Url"
                        ]
                        []
                    ]
                ]
            , div [ class "ui horizontal divider" ] [ text "Or" ]
            , div [ class "double-click-map ui right pointing large label" ] [ text "Double Click Map" ]
            ]
        , div [ class "ui hidden divider" ] []
        , div [ id "errors" ] [ text (model.error) ]
        , div [] []
        , div [ class "ui hidden divider" ] []
        , div [ id "locations-view" ] (LocationsView.view model)
        ]
