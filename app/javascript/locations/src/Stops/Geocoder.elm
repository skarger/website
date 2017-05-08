module Stops.Geocoder exposing (geocodeStops, handleGeocodingResponse, nameFromResult)

import Http
import List exposing (head)
import Dict exposing (Dict)
import Geocoding
import Messages exposing (Msg(StopsGeocoderResult))
import Models exposing (Model)
import Stops.Models
    exposing
        ( StopInput(..)
        , StopId
        , Stop(..)
        , StopArea
        , StopAreaId
        , Coordinates
        , CompleteStop
        , StopAreaStatus(..)
        )
import Stops.Stops as Stops
import Stops.Models exposing (extractStopInputId, toCompleteStop)


apiKey : String
apiKey =
    ""


geocodeStops : Dict StopAreaId StopArea -> Cmd Msg
geocodeStops stopAreas =
    Dict.map geocodeStop stopAreas |> Dict.values |> Cmd.batch


geocodeStop : StopAreaId -> StopArea -> Cmd Msg
geocodeStop stopAreaId stopArea =
    geocodingRequest stopAreaId stopArea


geocodingRequest : StopAreaId -> StopArea -> Cmd Msg
geocodingRequest id sa =
    case sa.stopInput of
        Address _ a ->
            forwardGeocode id sa a

        PointFromUrl _ lat lng ->
            reverseGeocode id sa lat lng

        PointFromMap _ lat lng ->
            reverseGeocode id sa lat lng


reverseGeocode : StopAreaId -> StopArea -> Float -> Float -> Cmd Msg
reverseGeocode stopAreaId stopArea lat lng =
    Geocoding.reverseRequestForLatLng apiKey ( lat, lng )
        |> Geocoding.sendReverseRequest (StopsGeocoderResult stopAreaId stopArea)


forwardGeocode : StopAreaId -> StopArea -> String -> Cmd Msg
forwardGeocode stopAreaId stopArea addr =
    Geocoding.requestForAddress apiKey addr
        |> Geocoding.send (StopsGeocoderResult stopAreaId stopArea)


handleGeocodingResponse :
    Model
    -> StopAreaId
    -> StopArea
    -> Result Http.Error Geocoding.Response
    -> ( Model, Cmd Msg )
handleGeocodingResponse model stopAreaId stopArea response =
    case extractResponseData response of
        Ok ( name, coords ) ->
            let
                stopId =
                    extractStopInputId stopArea.stopInput

                stop =
                    stopFromResponse model stopArea.stopInput name coords

                updatedModel =
                    Stops.updateStopArea model
                        stopAreaId
                        (Stops.overwriteWith
                            { stopArea
                                | stops = Dict.singleton stopId stop
                                , status = GeocodeSuccess
                            }
                        )

                updatedStopArea =
                    Dict.get stopAreaId updatedModel.stopAreas
            in
                case updatedStopArea of
                    Just sa ->
                        Stops.afterSuccessfulGeocode
                            updatedModel
                            stopAreaId
                            sa
                            (toCompleteStop stop)

                    Nothing ->
                        ( updatedModel, Cmd.none )

        Err error ->
            ( Stops.updateStopArea model
                stopAreaId
                (Stops.overwriteWith
                    { stopArea
                        | status = GeocodeFailure "Geocoding failed"
                    }
                )
            , Cmd.none
            )


stopFromResponse :
    Model
    -> StopInput
    -> String
    -> Coordinates
    -> Stop
stopFromResponse model stopInput name coords =
    let
        lat =
            coords.latitude

        lng =
            coords.longitude
    in
        case stopInput of
            PointFromMap stopId lat lng ->
                NewStop
                    { id = stopId
                    , latitude = lat
                    , longitude = lng
                    , name = name
                    , drawn = True
                    }

            PointFromUrl stopId lat lng ->
                NewStop
                    { id = stopId
                    , latitude = lat
                    , longitude = lng
                    , name = name
                    , drawn = False
                    }

            Address stopId _ ->
                NewStop
                    { id = stopId
                    , latitude = lat
                    , longitude = lng
                    , name = name
                    , drawn = False
                    }


extractResponseData : Result Http.Error Geocoding.Response -> Result String ( String, Coordinates )
extractResponseData response =
    case response of
        Ok resp ->
            let
                result =
                    head resp.results
            in
                case
                    ( Maybe.map nameFromResult result
                    , Maybe.map coordinatesFromResult result
                    )
                of
                    ( Just name, Just coords ) ->
                        Ok ( name, coords )

                    otherwise ->
                        Err "No geocoding results"

        Err _ ->
            Err "Geocoding request failed"


nameFromResult : Geocoding.GeocodingResult -> String
nameFromResult result =
    let
        includeComponent c =
            List.any
                ((flip List.member) c.types)
                [ Geocoding.StreetNumber
                , Geocoding.Route
                ]

        formatAddress xs =
            case xs of
                num :: route :: [] ->
                    String.join " " [ num, route ]

                _ ->
                    result.formattedAddress
    in
        result.addressComponents
            |> List.filter includeComponent
            |> List.filterMap .longName
            |> formatAddress


coordinatesFromResult : Geocoding.GeocodingResult -> Coordinates
coordinatesFromResult result =
    { latitude = result.geometry.location.latitude
    , longitude = result.geometry.location.longitude
    }
