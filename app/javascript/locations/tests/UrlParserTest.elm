module UrlParserTest exposing (..)

import Test exposing (..)
import Expect
import Models exposing (Model, emptyModel)
import Stops.UrlParser exposing (..)
import Stops.Models exposing (..)
import Random.Pcg exposing (initialSeed)


equalLocations : Result String (List StopInput) -> Result String (List StopInput) -> Bool
equalLocations expecteds actuals =
    let
        eqLoc expected actual =
            case expected of
                Address _ a ->
                    case actual of
                        Address _ b ->
                            a == b

                        otherwise ->
                            False

                PointFromUrl _ lat1 lng1 ->
                    case actual of
                        PointFromUrl _ lat2 lng2 ->
                            lat1 == lat2 && lng1 == lng2

                        otherwise ->
                            False

                PointFromMap _ lat1 lng1 ->
                    case actual of
                        PointFromMap _ lat2 lng2 ->
                            lat1 == lat2 && lng1 == lng2

                        otherwise ->
                            False
    in
        case expecteds of
            Ok exs ->
                case actuals of
                    Ok acs ->
                        List.map2 eqLoc exs acs |> List.all identity

                    Err _ ->
                        False

            Err ee ->
                case actuals of
                    Ok _ ->
                        False

                    Err ea ->
                        ee == ea


model : Model
model =
    emptyModel "waiting" (initialSeed 0)


all : Test
all =
    describe "Parse Google Maps directions URL as list of locations"
        [ test "Requires expected directions URL prefix" <|
            \() ->
                let
                    basicMapsUrlNotDirections =
                        "https://www.google.com/maps/@42.351188,-71.0794784,15z"
                in
                    Expect.equal (Err "Expected Google Maps directions URL starting with 'https://www.google.com/maps/dir'")
                        (parseStops model basicMapsUrlNotDirections
                            |> Result.map Tuple.second
                        )
        , test "Empty set of locations is OK" <|
            \() ->
                Expect.equal (Ok [])
                    (parseStops model "https://www.google.com/maps/dir///@42.351188,-71.0794784,15z"
                        |> Result.map Tuple.second
                    )
        , test "Just an origin is OK" <|
            \() ->
                Expect.true "parsed stops match expected aside from id" <|
                    equalLocations
                        (Ok [ PointFromUrl "id" 42.3589984 -71.0557432 ])
                        (parseStops model "https://www.google.com/maps/dir/42.3589984,-71.0557432//@42.3563243,-71.064889,16.89z"
                            |> Result.map Tuple.second
                        )
        , test "One origin and one destination is OK" <|
            \() ->
                Expect.true "parsed stops match expected aside from id" <|
                    equalLocations
                        (Ok
                            [ PointFromUrl "id" 42.3589984 -71.0557432
                            , PointFromUrl "id" 42.3616507 -71.0787134
                            ]
                        )
                        (parseStops model "https://www.google.com/maps/dir/42.3589984,-71.0557432/42.3616507,-71.0787134/@42.3563243,-71.064889,16.89z"
                            |> Result.map Tuple.second
                        )
        , test "Three or more waypoints is OK" <|
            \() ->
                Expect.true "parsed stops match expected aside from id" <|
                    equalLocations
                        (Ok
                            [ PointFromUrl "id" 42.3528572 -71.0739003
                            , PointFromUrl "id" 42.3511528 -71.0802099
                            , PointFromUrl "id" 42.3491268 -71.0883035
                            ]
                        )
                        (parseStops model "https://www.google.com/maps/dir/42.3528572,-71.0739003/42.3511528,-71.0802099/42.3491268,-71.0883035/@42.3563243,-71.064889,16.89z"
                            |> Result.map Tuple.second
                        )
        , test "textual locations are OK" <|
            \() ->
                Expect.true "parsed stops match expected aside from id" <|
                    equalLocations
                        (Ok
                            [ Address "id" "283+Newbury+St,+Boston,+MA+02115"
                            , Address "id" "1380+Commonwealth+Avenue,+Boston,+MA+02134"
                            ]
                        )
                        (parseStops model "https://www.google.com/maps/dir/283+Newbury+St,+Boston,+MA+02115/1380+Commonwealth+Avenue,+Boston,+MA+02134/@42.350684,-71.1216698,14z/data="
                            |> Result.map Tuple.second
                        )
        , test "mix of lat,lng points and textual addresses is OK" <|
            \() ->
                Expect.true "parsed stops match expected aside from id" <|
                    equalLocations
                        (Ok
                            [ PointFromUrl "id" 42.3491268 -71.0883035
                            , Address "id" "283+Newbury+St,+Boston,+MA+02115"
                            ]
                        )
                        (parseStops model "https://www.google.com/maps/dir/42.3491268,-71.0883035/283+Newbury+St,+Boston,+MA+02115/@42.350684,-71.1216698,14z/data="
                            |> Result.map Tuple.second
                        )
        ]
