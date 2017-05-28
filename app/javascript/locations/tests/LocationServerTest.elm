module LocationServerTest exposing (..)

import Test exposing (..)
import Expect
import Http exposing (jsonBody)
import Json.Encode exposing (object, list, string, float)
import Locations.Models exposing (Location(..), toCompleteLocation)
import Locations.Server exposing (serializeLocations)


all : Test
all =
    describe "Location-related server interaction"
        [ describe "Location area collection serialization"
            [ test "serializes empty set of Locations" <|
                \() ->
                    Expect.equal
                        (jsonBody
                            (object
                                [ ( "data", list [] )
                                ]
                            )
                        )
                        (serializeLocations [])
            , test "serializes non-empty list of locations" <|
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
                                |> toCompleteLocation
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
                            (serializeLocations [ newLocation ])
            ]
        ]
