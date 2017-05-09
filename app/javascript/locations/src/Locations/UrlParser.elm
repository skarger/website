module Locations.UrlParser exposing (parseLocations)

import Random.Pcg exposing (Seed)
import UuidHelpers exposing (generateUuids)
import Combine
    exposing
        ( Parser
        , parse
        , string
        , regex
        , sepEndBy
        , or
        , (<$>)
        , (<?>)
        , (<*>)
        , (<*)
        , (*>)
        )
import Combine.Num exposing (float)
import Models exposing (Model)
import Locations.Models exposing (..)


type ParsedPoint
    = PointLatLng Float Float
    | PointAddress String


type alias ParseError =
    String


parseLocations : Model -> String -> Result String ( Seed, List LocationInput )
parseLocations model url =
    case parseUrl url of
        Ok parsedPoints ->
            let
                ( newSeed, newLocations ) =
                    toLocationList model.currentSeed parsedPoints
            in
                Ok ( newSeed, newLocations )

        Err error ->
            Err error


toLocationList : Seed -> List ParsedPoint -> ( Seed, List LocationInput )
toLocationList seed parsedPoints =
    generateUuids seed parsedPoints
        |> Tuple.mapSecond
            (List.map toLocationInput << List.map2 (,) parsedPoints)


toLocationInput : ( ParsedPoint, LocationId ) -> LocationInput
toLocationInput ( pl, id ) =
    case pl of
        PointLatLng lat lng ->
            LatLngFromUrl id lat lng

        PointAddress name ->
            Address id name


parseUrl : String -> Result ParseError (List ParsedPoint)
parseUrl url =
    case parse lineParser url of
        Err ( _, _, errors ) ->
            Err <| String.join " or " errors

        Ok ( _, _, result ) ->
            Ok result


lineParser : Parser s (List ParsedPoint)
lineParser =
    prefix *> points <* suffix


prefix : Parser s String
prefix =
    string "https://www.google.com/maps/dir/"
        <?> ("Expected Google Maps directions URL starting with "
                ++ "'https://www.google.com/maps/dir'"
            )


suffix : Parser s String
suffix =
    regex ".*$"


points : Parser s (List ParsedPoint)
points =
    sepEndBy (string "/") (or latLng address)


latLng : Parser s ParsedPoint
latLng =
    ((PointLatLng) <$> latitude <*> longitude)


latitude : Parser s Float
latitude =
    float <* comma


longitude : Parser s Float
longitude =
    float


comma : Parser s String
comma =
    string ","



-- url suffix has format /@<map center>,<zoom level>/data=
-- example: .../283+Newbury+St/@42.3563243,-71.064889,16.89z/data=!3m...
-- to avoid reading the suffix as a textual address we reject characters [/@]


address : Parser s ParsedPoint
address =
    PointAddress <$> regex "[^/@]+"
