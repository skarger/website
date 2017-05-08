module UuidHelpersTest exposing (..)

import Test exposing (..)
import Expect
import Fuzz exposing (list, int)
import UuidHelpers exposing (generateUuids)
import Random.Pcg exposing (Seed, initialSeed, step)
import Uuid exposing (uuidGenerator)
import Dict
import Debug


all : Test
all =
    describe "returns a list with uuids for each item of the list"
        [ fuzz (list int) "provides a list with the same length as the given list" <|
            \fuzzList ->
                fuzzList
                    |> generateUuids (initialSeed 0)
                    |> Tuple.second
                    |> List.length
                    |> Expect.equal (List.length fuzzList)
        , fuzz (list int) "UUID generator stepped for each item in the given list" <|
            \fuzzList ->
                let
                    firstSeed =
                        initialSeed 0

                    ( actualSeed, _ ) =
                        generateUuids (firstSeed) fuzzList

                    expectedSeed =
                        stepSeed (List.length fuzzList) firstSeed
                in
                    Expect.equal actualSeed expectedSeed
        ]


stepSeed : Int -> Seed -> Seed
stepSeed count seed =
    if count == 0 then
        seed
    else
        let
            ( _, newSeed ) =
                step uuidGenerator seed
        in
            stepSeed (count - 1) newSeed
