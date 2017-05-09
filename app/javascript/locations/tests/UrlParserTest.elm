module UrlParserTest exposing (..)

import Test exposing (..)
import Expect
import Models exposing (Model, emptyModel)
import Locations.UrlParser exposing (..)
import Locations.Models exposing (..)
import Random.Pcg exposing (initialSeed)


equalPoints : Result String (List LocationInput) -> Result String (List LocationInput) -> Bool
equalPoints expecteds actuals =
    let
        eqLoc expected actual =
            case expected of
                Address _ a ->
                    case actual of
                        Address _ b ->
                            a == b

                        otherwise ->
                            False

                LatLngFromUrl _ lat1 lng1 ->
                    case actual of
                        LatLngFromUrl _ lat2 lng2 ->
                            lat1 == lat2 && lng1 == lng2

                        otherwise ->
                            False

                LatLngFromMap _ lat1 lng1 ->
                    case actual of
                        LatLngFromMap _ lat2 lng2 ->
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
                        (parseLocations model basicMapsUrlNotDirections
                            |> Result.map Tuple.second
                        )
        , test "Empty set of locations is OK" <|
            \() ->
                Expect.equal (Ok [])
                    (parseLocations model "https://www.google.com/maps/dir///@42.351188,-71.0794784,15z"
                        |> Result.map Tuple.second
                    )
        , test "Just an origin is OK" <|
            \() ->
                Expect.true "parsed locations match expected aside from id" <|
                    equalPoints
                        (Ok [ LatLngFromUrl "id" 42.3589984 -71.0557432 ])
                        (parseLocations model "https://www.google.com/maps/dir/42.3589984,-71.0557432//@42.3563243,-71.064889,16.89z"
                            |> Result.map Tuple.second
                        )
        , test "One origin and one destination is OK" <|
            \() ->
                Expect.true "parsed locations match expected aside from id" <|
                    equalPoints
                        (Ok
                            [ LatLngFromUrl "id" 42.3589984 -71.0557432
                            , LatLngFromUrl "id" 42.3616507 -71.0787134
                            ]
                        )
                        (parseLocations model "https://www.google.com/maps/dir/42.3589984,-71.0557432/42.3616507,-71.0787134/@42.3563243,-71.064889,16.89z"
                            |> Result.map Tuple.second
                        )
        , test "Three or more waypoints is OK" <|
            \() ->
                Expect.true "parsed locations match expected aside from id" <|
                    equalPoints
                        (Ok
                            [ LatLngFromUrl "id" 42.3528572 -71.0739003
                            , LatLngFromUrl "id" 42.3511528 -71.0802099
                            , LatLngFromUrl "id" 42.3491268 -71.0883035
                            ]
                        )
                        (parseLocations model "https://www.google.com/maps/dir/42.3528572,-71.0739003/42.3511528,-71.0802099/42.3491268,-71.0883035/@42.3563243,-71.064889,16.89z"
                            |> Result.map Tuple.second
                        )
        , test "textual locations are OK" <|
            \() ->
                Expect.true "parsed locations match expected aside from id" <|
                    equalPoints
                        (Ok
                            [ Address "id" "283+Newbury+St,+Boston,+MA+02115"
                            , Address "id" "1380+Commonwealth+Avenue,+Boston,+MA+02134"
                            ]
                        )
                        (parseLocations model "https://www.google.com/maps/dir/283+Newbury+St,+Boston,+MA+02115/1380+Commonwealth+Avenue,+Boston,+MA+02134/@42.350684,-71.1216698,14z/data="
                            |> Result.map Tuple.second
                        )
        , test "mix of lat,lng points and textual addresses is OK" <|
            \() ->
                Expect.true "parsed locations match expected aside from id" <|
                    equalPoints
                        (Ok
                            [ LatLngFromUrl "id" 42.3491268 -71.0883035
                            , Address "id" "283+Newbury+St,+Boston,+MA+02115"
                            ]
                        )
                        (parseLocations model "https://www.google.com/maps/dir/42.3491268,-71.0883035/283+Newbury+St,+Boston,+MA+02115/@42.350684,-71.1216698,14z/data="
                            |> Result.map Tuple.second
                        )
        ]
