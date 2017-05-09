module LocationAreaValidatorTest exposing (..)

import Test exposing (..)
import Expect
import Dict exposing (Dict)
import Random.Pcg exposing (initialSeed)
import Models exposing (Model, emptyModel)
import Locations.Models exposing (LocationInput(..), LocationId, Location(..), LocationArea, LocationAreaStatus(..))
import Locations.AreaValidator as LocationAreaValidator


testNewLocation : LocationId -> String -> Location
testNewLocation locationId name =
    NewLocation
        { id = locationId
        , name = name
        , latitude = 1.0
        , longitude = 2.0
        , drawn = True
        }


testLocationArea : LocationId -> Maybe Location -> LocationArea
testLocationArea locationId chosen =
    { locationInput = LatLngFromUrl locationId 1.0 2.0
    , status = GeocodeSuccess
    , locations = Dict.empty
    , chosen = chosen
    }


testModel : Dict Int LocationArea -> Model
testModel locationAreas =
    let
        baseModel =
            emptyModel "waiting" (initialSeed 0)
    in
        { baseModel | locationAreas = locationAreas }


all : Test
all =
    describe "LocationAreaValidator"
        [ describe ".validateLocationArea"
            [ test "is valid for a LocationArea with a chosen location" <|
                \() ->
                    let
                        locationId =
                            "id1"

                        name =
                            "test name"

                        locationArea =
                            testLocationArea locationId (Just <| testNewLocation locationId name)
                    in
                        Expect.equal
                            ({ locationArea | status = Valid })
                            (LocationAreaValidator.validateLocationArea locationArea)
            , test "is not valid when no location chosen" <|
                \() ->
                    let
                        locationId =
                            "id1"

                        name =
                            "test name"

                        locationArea =
                            testLocationArea locationId Nothing
                    in
                        Expect.equal
                            ({ locationArea | status = Invalid "Please choose a location" })
                            (LocationAreaValidator.validateLocationArea locationArea)
            , test "is not valid when chosen location has empty name" <|
                \() ->
                    let
                        locationId =
                            "id1"

                        name =
                            ""

                        locationArea =
                            testLocationArea locationId (Just <| testNewLocation locationId name)
                    in
                        Expect.equal
                            ({ locationArea | status = Invalid "Location name cannot be empty" })
                            (LocationAreaValidator.validateLocationArea locationArea)
            ]
        , describe ".validate"
            [ test "returns model with updated Valid LocationArea status" <|
                \() ->
                    let
                        locationId =
                            "id1"

                        name =
                            "test name"

                        locationAreaId =
                            1

                        locationArea =
                            testLocationArea locationId (Just <| testNewLocation locationId name)

                        initialModel =
                            testModel (Dict.singleton locationAreaId locationArea)

                        updatedLocationAreas =
                            Dict.singleton locationAreaId
                                { locationArea
                                    | status = Valid
                                }
                    in
                        Expect.equal
                            { initialModel | locationAreas = updatedLocationAreas }
                            (LocationAreaValidator.validate initialModel locationAreaId)
            , test "returns model with updated Invalid LocationArea status" <|
                \() ->
                    let
                        locationId =
                            "id1"

                        locationAreaId =
                            1

                        locationArea =
                            testLocationArea locationId Nothing

                        initialModel =
                            testModel (Dict.singleton locationAreaId locationArea)

                        updatedLocationAreas =
                            Dict.singleton locationAreaId
                                { locationArea
                                    | status = Invalid "Please choose a location"
                                }
                    in
                        Expect.equal
                            { initialModel | locationAreas = updatedLocationAreas }
                            (LocationAreaValidator.validate initialModel locationAreaId)
            ]
        , describe ".validateAll"
            [ test "returns False if any LocationArea invalid" <|
                \() ->
                    let
                        locationArea1 =
                            testLocationArea "id1" (Just <| testNewLocation "id1" "test name")

                        locationArea2 =
                            testLocationArea "id2" Nothing

                        model =
                            testModel (Dict.fromList [ ( 1, locationArea1 ), ( 2, locationArea2 ) ])
                    in
                        Expect.equal False (LocationAreaValidator.allValid model)
            , test "returns True if all LocationAreas valid" <|
                \() ->
                    let
                        locationArea1 =
                            testLocationArea "id1" (Just <| testNewLocation "id1" "test name 1")

                        locationArea2 =
                            testLocationArea "id2" (Just <| testNewLocation "id2" "test name 2")

                        model =
                            testModel (Dict.fromList [ ( 1, locationArea1 ), ( 2, locationArea2 ) ])
                    in
                        Expect.equal True (LocationAreaValidator.allValid model)
            ]
        ]
