module StopServerTest exposing (..)

import Test exposing (..)
import Expect
import Http exposing (jsonBody)
import Json.Encode exposing (object, list, string, float)
import Dict exposing (Dict)
import Stops.Models exposing (StopInput(..), StopId, Stop(..), StopArea, StopAreaStatus(..))
import Stops.Server exposing (serializeStopAreas)


all : Test
all =
    describe "Stop-related server interaction"
        [ describe "Stop area collection serialization"
            [ test "serializes empty set of StopAreas" <|
                \() ->
                    let
                        stopAreas =
                            Dict.empty
                    in
                        Expect.equal
                            (jsonBody
                                (object
                                    [ ( "data", list [] )
                                    ]
                                )
                            )
                            (serializeStopAreas stopAreas)
            , test "serializes chosen stop" <|
                \() ->
                    let
                        newStop =
                            NewStop
                                { id = "id1"
                                , name = "test name"
                                , latitude = 1.23
                                , longitude = -4.56
                                , drawn = True
                                }

                        stopAreas =
                            Dict.singleton 1
                                { stopInput = Address "id1" "test"
                                , status = Valid
                                , stops = Dict.singleton "id1" newStop
                                , chosen = Just newStop
                                }
                    in
                        Expect.equal
                            (jsonBody
                                (object
                                    [ ( "data"
                                      , list
                                            [ object
                                                [ ( "type", string "stops" )
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
                            (serializeStopAreas stopAreas)
            , test "serializes only NewStops from chosen set" <|
                \() ->
                    let
                        newStop =
                            NewStop
                                { id = "id1"
                                , name = "test name"
                                , latitude = 1.23
                                , longitude = -4.56
                                , drawn = True
                                }

                        existingStop =
                            ExistingStop
                                { id = "id2"
                                , name = "test name"
                                , latitude = 7.89
                                , longitude = -0.12
                                , drawn = True
                                }

                        stopAreas =
                            Dict.fromList
                                [ ( 1
                                  , { stopInput = Address "id1" "test new"
                                    , status = Valid
                                    , stops = Dict.singleton "id1" newStop
                                    , chosen = Just newStop
                                    }
                                  )
                                , ( 2
                                  , { stopInput = Address "id2" "test existing"
                                    , status = Valid
                                    , stops = Dict.singleton "id2" existingStop
                                    , chosen = Just existingStop
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
                                                [ ( "type", string "stops" )
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
                            (serializeStopAreas stopAreas)
            ]
        ]
