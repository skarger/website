module StopAreaValidatorTest exposing (..)

import Test exposing (..)
import Expect
import Dict exposing (Dict)
import Random.Pcg exposing (initialSeed)
import Models exposing (Model, emptyModel)
import Stops.Models exposing (StopInput(..), StopId, Stop(..), StopArea, StopAreaStatus(..))
import Stops.AreaValidator as StopAreaValidator


testNewStop : StopId -> String -> Stop
testNewStop stopId name =
    NewStop
        { id = stopId
        , name = name
        , latitude = 1.0
        , longitude = 2.0
        , drawn = True
        }


testStopArea : StopId -> Maybe Stop -> StopArea
testStopArea stopId chosen =
    { stopInput = PointFromUrl stopId 1.0 2.0
    , status = GeocodeSuccess
    , stops = Dict.empty
    , chosen = chosen
    }


testModel : Dict Int StopArea -> Model
testModel stopAreas =
    let
        baseModel =
            emptyModel "waiting" (initialSeed 0)
    in
        { baseModel | stopAreas = stopAreas }


all : Test
all =
    describe "StopAreaValidator"
        [ describe ".validateStopArea"
            [ test "is valid for a StopArea with a chosen stop" <|
                \() ->
                    let
                        stopId =
                            "id1"

                        name =
                            "test name"

                        stopArea =
                            testStopArea stopId (Just <| testNewStop stopId name)
                    in
                        Expect.equal
                            ({ stopArea | status = Valid })
                            (StopAreaValidator.validateStopArea stopArea)
            , test "is not valid when no stop chosen" <|
                \() ->
                    let
                        stopId =
                            "id1"

                        name =
                            "test name"

                        stopArea =
                            testStopArea stopId Nothing
                    in
                        Expect.equal
                            ({ stopArea | status = Invalid "Please choose a location" })
                            (StopAreaValidator.validateStopArea stopArea)
            , test "is not valid when chosen stop has empty name" <|
                \() ->
                    let
                        stopId =
                            "id1"

                        name =
                            ""

                        stopArea =
                            testStopArea stopId (Just <| testNewStop stopId name)
                    in
                        Expect.equal
                            ({ stopArea | status = Invalid "Location name cannot be empty" })
                            (StopAreaValidator.validateStopArea stopArea)
            ]
        , describe ".validate"
            [ test "returns model with updated Valid StopArea status" <|
                \() ->
                    let
                        stopId =
                            "id1"

                        name =
                            "test name"

                        stopAreaId =
                            1

                        stopArea =
                            testStopArea stopId (Just <| testNewStop stopId name)

                        initialModel =
                            testModel (Dict.singleton stopAreaId stopArea)

                        updatedStopAreas =
                            Dict.singleton stopAreaId
                                { stopArea
                                    | status = Valid
                                }
                    in
                        Expect.equal
                            { initialModel | stopAreas = updatedStopAreas }
                            (StopAreaValidator.validate initialModel stopAreaId)
            , test "returns model with updated Invalid StopArea status" <|
                \() ->
                    let
                        stopId =
                            "id1"

                        stopAreaId =
                            1

                        stopArea =
                            testStopArea stopId Nothing

                        initialModel =
                            testModel (Dict.singleton stopAreaId stopArea)

                        updatedStopAreas =
                            Dict.singleton stopAreaId
                                { stopArea
                                    | status = Invalid "Please choose a stop"
                                }
                    in
                        Expect.equal
                            { initialModel | stopAreas = updatedStopAreas }
                            (StopAreaValidator.validate initialModel stopAreaId)
            ]
        , describe ".validateAll"
            [ test "returns False if any StopArea invalid" <|
                \() ->
                    let
                        stopArea1 =
                            testStopArea "id1" (Just <| testNewStop "id1" "test name")

                        stopArea2 =
                            testStopArea "id2" Nothing

                        model =
                            testModel (Dict.fromList [ ( 1, stopArea1 ), ( 2, stopArea2 ) ])
                    in
                        Expect.equal False (StopAreaValidator.allValid model)
            , test "returns True if all StopAreas valid" <|
                \() ->
                    let
                        stopArea1 =
                            testStopArea "id1" (Just <| testNewStop "id1" "test name 1")

                        stopArea2 =
                            testStopArea "id2" (Just <| testNewStop "id2" "test name 2")

                        model =
                            testModel (Dict.fromList [ ( 1, stopArea1 ), ( 2, stopArea2 ) ])
                    in
                        Expect.equal True (StopAreaValidator.allValid model)
            ]
        ]
