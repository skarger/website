port module Main exposing (..)

import Test
import Test.Runner.Node exposing (run, TestProgram)
import Json.Encode exposing (Value)
import UrlParserTest
import StopsGeocoderTest
import UuidHelpersTest
import StopAreaValidatorTest
import StopServerTest


main : TestProgram
main =
    run emit <|
        Test.concat
            [ UrlParserTest.all
            , UuidHelpersTest.all
            , StopsGeocoderTest.all
            , StopAreaValidatorTest.all
            , StopServerTest.all
            ]


port emit : ( String, Value ) -> Cmd msg
