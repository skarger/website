port module Main exposing (..)

import Test
import Test.Runner.Node exposing (run, TestProgram)
import Json.Encode exposing (Value)
import UrlParserTest
import LocationsGeocoderTest
import UuidHelpersTest
import LocationAreaValidatorTest
import LocationServerTest
import LocationsTest


main : TestProgram
main =
    run emit <|
        Test.concat
            [ UrlParserTest.all
            , UuidHelpersTest.all
            , LocationsGeocoderTest.all
            , LocationAreaValidatorTest.all
            , LocationServerTest.all
            , LocationsTest.all
            ]


port emit : ( String, Value ) -> Cmd msg
