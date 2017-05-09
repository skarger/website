module Locations.Geocoder exposing (geocodeLocations, handleGeocodingResponse, nameFromResult)

import Http
import List exposing (head)
import Dict exposing (Dict)
import Geocoding
import Messages exposing (Msg(LocationsGeocoderResult))
import Models exposing (Model)
import Locations.Models
    exposing
        ( LocationInput(..)
        , LocationId
        , Location(..)
        , LocationArea
        , LocationAreaId
        , Coordinates
        , CompleteLocation
        , LocationAreaStatus(..)
        )
import Locations.Locations as Locations
import Locations.Models exposing (extractLocationInputId, toCompleteLocation)


apiKey : String
apiKey =
    ""


geocodeLocations : Dict LocationAreaId LocationArea -> Cmd Msg
geocodeLocations locationAreas =
    Dict.map geocodeLocation locationAreas |> Dict.values |> Cmd.batch


geocodeLocation : LocationAreaId -> LocationArea -> Cmd Msg
geocodeLocation locationAreaId locationArea =
    geocodingRequest locationAreaId locationArea


geocodingRequest : LocationAreaId -> LocationArea -> Cmd Msg
geocodingRequest id sa =
    case sa.locationInput of
        Address _ a ->
            forwardGeocode id sa a

        LatLngFromUrl _ lat lng ->
            reverseGeocode id sa lat lng

        LatLngFromMap _ lat lng ->
            reverseGeocode id sa lat lng


reverseGeocode : LocationAreaId -> LocationArea -> Float -> Float -> Cmd Msg
reverseGeocode locationAreaId locationArea lat lng =
    Geocoding.reverseRequestForLatLng apiKey ( lat, lng )
        |> Geocoding.sendReverseRequest (LocationsGeocoderResult locationAreaId locationArea)


forwardGeocode : LocationAreaId -> LocationArea -> String -> Cmd Msg
forwardGeocode locationAreaId locationArea addr =
    Geocoding.requestForAddress apiKey addr
        |> Geocoding.send (LocationsGeocoderResult locationAreaId locationArea)


handleGeocodingResponse :
    Model
    -> LocationAreaId
    -> LocationArea
    -> Result Http.Error Geocoding.Response
    -> ( Model, Cmd Msg )
handleGeocodingResponse model locationAreaId locationArea response =
    case extractResponseData response of
        Ok ( name, coords ) ->
            let
                locationId =
                    extractLocationInputId locationArea.locationInput

                location =
                    locationFromResponse model locationArea.locationInput name coords

                updatedModel =
                    Locations.updateLocationArea model
                        locationAreaId
                        (Locations.overwriteWith
                            { locationArea
                                | locations = Dict.singleton locationId location
                                , status = GeocodeSuccess
                            }
                        )

                updatedLocationArea =
                    Dict.get locationAreaId updatedModel.locationAreas
            in
                case updatedLocationArea of
                    Just sa ->
                        Locations.afterSuccessfulGeocode
                            updatedModel
                            locationAreaId
                            sa
                            (toCompleteLocation location)

                    Nothing ->
                        ( updatedModel, Cmd.none )

        Err error ->
            ( Locations.updateLocationArea model
                locationAreaId
                (Locations.overwriteWith
                    { locationArea
                        | status = GeocodeFailure "Geocoding failed"
                    }
                )
            , Cmd.none
            )


locationFromResponse :
    Model
    -> LocationInput
    -> String
    -> Coordinates
    -> Location
locationFromResponse model locationInput name coords =
    let
        lat =
            coords.latitude

        lng =
            coords.longitude
    in
        case locationInput of
            LatLngFromMap locationId lat lng ->
                NewLocation
                    { id = locationId
                    , latitude = lat
                    , longitude = lng
                    , name = name
                    , drawn = True
                    }

            LatLngFromUrl locationId lat lng ->
                NewLocation
                    { id = locationId
                    , latitude = lat
                    , longitude = lng
                    , name = name
                    , drawn = False
                    }

            Address locationId _ ->
                NewLocation
                    { id = locationId
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
