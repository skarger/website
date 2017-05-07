module Stops.UrlParser exposing (parseStops)

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
import Stops.Models exposing (..)


type ParsedLocation
    = LocationPoint Float Float
    | LocationAddress String


type alias ParseError =
    String


parseStops : Model -> String -> Result String ( Seed, List StopInput )
parseStops model url =
    case parseUrl url of
        Ok parsedLocations ->
            let
                ( newSeed, newStops ) =
                    toStopList model.currentSeed parsedLocations
            in
                Ok ( newSeed, newStops )

        Err error ->
            Err error


toStopList : Seed -> List ParsedLocation -> ( Seed, List StopInput )
toStopList seed parsedLocations =
    generateUuids seed parsedLocations
        |> Tuple.mapSecond
            (List.map toStopInput << List.map2 (,) parsedLocations)


toStopInput : ( ParsedLocation, StopId ) -> StopInput
toStopInput ( pl, id ) =
    case pl of
        LocationPoint lat lng ->
            PointFromUrl id lat lng

        LocationAddress name ->
            Address id name


parseUrl : String -> Result ParseError (List ParsedLocation)
parseUrl url =
    case parse lineParser url of
        Err ( _, _, errors ) ->
            Err <| String.join " or " errors

        Ok ( _, _, result ) ->
            Ok result


lineParser : Parser s (List ParsedLocation)
lineParser =
    prefix *> locations <* suffix


prefix : Parser s String
prefix =
    string "https://www.google.com/maps/dir/"
        <?> ("Expected Google Maps directions URL starting with "
                ++ "'https://www.google.com/maps/dir'"
            )


suffix : Parser s String
suffix =
    regex ".*$"


locations : Parser s (List ParsedLocation)
locations =
    sepEndBy (string "/") (or point address)


point : Parser s ParsedLocation
point =
    ((LocationPoint) <$> latitude <*> longitude)


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


address : Parser s ParsedLocation
address =
    LocationAddress <$> regex "[^/@]+"
