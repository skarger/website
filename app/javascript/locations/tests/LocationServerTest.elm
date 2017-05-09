module LocationServerTest exposing (..)

import Test exposing (..)
import Expect
import Http exposing (jsonBody)
import Json.Encode exposing (object, list, string, float)
import Dict exposing (Dict)
import Locations.Models exposing (LocationInput(..), LocationId, Location(..), LocationArea, LocationAreaStatus(..))
import Locations.Server exposing (serializeLocationAreas)


all : Test
all =
    describe "Location-related server interaction"
        [ describe "Location area collection serialization"
            [ test "serializes empty set of LocationAreas" <|
                \() ->
                    let
                        locationAreas =
                            Dict.empty
                    in
                        Expect.equal
                            (jsonBody
                                (object
                                    [ ( "data", list [] )
                                    ]
                                )
                            )
                            (serializeLocationAreas locationAreas)
            , test "serializes chosen location" <|
                \() ->
                    let
                        newLocation =
                            NewLocation
                                { id = "id1"
                                , name = "test name"
                                , latitude = 1.23
                                , longitude = -4.56
                                , drawn = True
                                }

                        locationAreas =
                            Dict.singleton 1
                                { locationInput = Address "id1" "test"
                                , status = Valid
                                , locations = Dict.singleton "id1" newLocation
                                , chosen = Just newLocation
                                }
                    in
                        Expect.equal
                            (jsonBody
                                (object
                                    [ ( "data"
                                      , list
                                            [ object
                                                [ ( "type", string "locations" )
                                                , ( "id", string "id1" )
                                                , ( "attributes"
                                                  , object
                                                        [ ( "name", string "test name" )
                                                        , ( "latitude", float 1.23 )
                                                        , ( "longitude", float -4.56 )
                                                        ]
                                                  )
                                                ]
                                            ]
                                      )
                                    ]
                                )
                            )
                            (serializeLocationAreas locationAreas)
            , test "serializes only NewLocations from chosen set" <|
                \() ->
                    let
                        newLocation =
                            NewLocation
                                { id = "id1"
                                , name = "test name"
                                , latitude = 1.23
                                , longitude = -4.56
                                , drawn = True
                                }

                        existingLocation =
                            ExistingLocation
                                { id = "id2"
                                , name = "test name"
                                , latitude = 7.89
                                , longitude = -0.12
                                , drawn = True
                                }

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
                        Expect.equal
                            (jsonBody
                                (object
                                    [ ( "data"
                                      , list
                                            [ object
                                                [ ( "type", string "locations" )
                                                , ( "id", string "id1" )
                                                , ( "attributes"
                                                  , object
                                                        [ ( "name", string "test name" )
                                                        , ( "latitude", float 1.23 )
                                                        , ( "longitude", float -4.56 )
                                                        ]
                                                  )
                                                ]
                                            ]
                                      )
                                    ]
                                )
                            )
                            (serializeLocationAreas locationAreas)
            ]
        ]
