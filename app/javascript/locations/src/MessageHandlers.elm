module MessageHandlers exposing (integrateParsedLocations, integrateDoubleClickLocation)

import Models exposing (Model)
import Messages exposing (Msg(..))
import Locations.Models exposing (LocationInput(..))
import Locations.Locations as Locations
import Locations.Geocoder as LocationsGeocoder
import GoogleMaps exposing (MapPoint)
import Random.Pcg exposing (Seed)
import Dict exposing (Dict)


integrateParsedLocations :
    Model
    -> String
    -> Result String ( Seed, List LocationInput )
    -> ( Model, Cmd Msg )
integrateParsedLocations model url result =
    case result of
        Ok ( newSeed, parsedLocations ) ->
            let
                newLocationAreaIndex =
                    model.locationAreaIndex + List.length parsedLocations

                newLocationAreas =
                    Dict.fromList <|
                        List.indexedMap
                            (\i pl ->
                                ( i + model.locationAreaIndex
                                , Locations.initializeLocationArea pl
                                )
                            )
                            parsedLocations
            in
                ( { model
                    | url = url
                    , locationAreas = Dict.union model.locationAreas newLocationAreas
                    , error = ""
                    , locationAreaIndex = newLocationAreaIndex
                    , currentSeed = newSeed
                  }
                , LocationsGeocoder.geocodeLocations newLocationAreas
                )

        Err error ->
            ( { model
                | url = url
                , error = error
              }
            , Cmd.none
            )


integrateDoubleClickLocation : Model -> MapPoint -> ( Model, Cmd Msg )
integrateDoubleClickLocation model coordinates =
    let
        drawn =
            True

        locationInput =
            LatLngFromMap coordinates.id
                coordinates.latitude
                coordinates.longitude

        key =
            model.locationAreaIndex

        locationArea =
            Locations.initializeLocationArea locationInput
    in
        ( { model
            | locationAreas =
                Dict.insert key locationArea model.locationAreas
            , locationAreaIndex = key + 1
          }
        , LocationsGeocoder.geocodeLocations (Dict.singleton key locationArea)
        )
