module LocationsTest exposing (..)

import Test exposing (..)
import Expect
import Dict exposing (Dict)
import Locations.Models exposing (LocationInput(..), LocationId, Location(..), LocationArea, LocationAreaStatus(..), toCompleteLocation)
import Locations.Locations as Locations


testNewLocation : LocationId -> String -> Location
testNewLocation locationId name =
    NewLocation
        { id = locationId
        , name = name
        , latitude = 1.0
        , longitude = 2.0
        , drawn = True
        }


testExistingLocation : LocationId -> String -> Location
testExistingLocation locationId name =
    ExistingLocation
        { id = locationId
        , name = name
        , latitude = 1.0
        , longitude = 2.0
        , drawn = True
        }


testLocationArea : LocationId -> Maybe Location -> LocationArea
testLocationArea locationId chosen =
    { locationInput = LatLngFromUrl locationId 1.0 2.0
    , status = Valid
    , locations = Dict.empty
    , chosen = chosen
    }


all : Test
all =
    describe "Locations"
        [ describe ".chosenNewLocations"
            [ test "returns empty list if no new locations chosen" <|
                \() ->
                    let
                        locationId =
                            "id1"

                        name =
                            "test name"

                        chosen =
                            Just <| testExistingLocation locationId name

                        locationAreas =
                            Dict.fromList
                                [ ( 1, (testLocationArea locationId chosen) )
                                ]
                    in
                        Expect.equal [] <| Locations.chosenNewLocations locationAreas
            , test "returns only NewLocations from chosen set" <|
                \() ->
                    let
                        newLocation =
                            testNewLocation "id1" "test name"

                        existingLocation =
                            testExistingLocation "id2" "test name"

                        locationAreas =
                            Dict.fromList
                                [ ( 1
                                  , { locationInput = Address "id1" "test new"
                                    , status = Valid
                                    , locations = Dict.singleton "id1" newLocation
                                    , chosen = Just newLocation
                                    }
                                  )
                                , ( 2
                                  , { locationInput = Address "id2" "test existing"
                                    , status = Valid
                                    , locations = Dict.singleton "id2" existingLocation
                                    , chosen = Just existingLocation
                                    }
                                  )
                                ]
                    in
                        Expect.equal [ toCompleteLocation newLocation ]
                            (Locations.chosenNewLocations locationAreas)
            ]
        ]
