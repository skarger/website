module Stops.Server exposing (fetchPossibleDuplicates, serializeStopAreas, saveStopsToServer, noContentResponse)

import Http exposing (Body, Error(..), jsonBody)
import Json.Decode exposing (Decoder, at)
import Json.Decode.Pipeline exposing (decode, required, requiredAt, hardcoded)
import Json.Encode exposing (Value)
import Dict exposing (Dict)
import Messages exposing (Msg(..))
import Stops.Models exposing (CompleteStop, Stop(..), StopAreaId, StopArea)


fetchPossibleDuplicates : StopAreaId -> CompleteStop -> Cmd Msg
fetchPossibleDuplicates stopAreaId stop =
    let
        latitude =
            stop.latitude

        longitude =
            stop.longitude

        path =
            "/api/nearby_locations"

        query =
            queryString
                [ ( "latitude", toString latitude )
                , ( "longitude", toString longitude )
                ]

        request =
            Http.get (path ++ query) decodeExistingStops
    in
        Http.send (PossibleDuplicateStops stopAreaId) request


queryString : List ( String, String ) -> String
queryString kvs =
    let
        encodeTuple =
            Tuple.mapFirst Http.encodeUri << Tuple.mapSecond Http.encodeUri
    in
        List.map encodeTuple kvs
            |> List.map (\( k, v ) -> k ++ "=" ++ v)
            |> String.join "&"
            |> String.cons '?'


decodeCompleteStop : Decoder CompleteStop
decodeCompleteStop =
    let
        drawn =
            False
    in
        decode CompleteStop
            |> required "id" Json.Decode.string
            |> requiredAt [ "attributes" ] (Json.Decode.field "name" Json.Decode.string)
            |> requiredAt [ "attributes" ] (Json.Decode.field "latitude" Json.Decode.float)
            |> requiredAt [ "attributes" ] (Json.Decode.field "longitude" Json.Decode.float)
            |> hardcoded drawn


decodeExistingStop : Decoder Stop
decodeExistingStop =
    Json.Decode.map ExistingStop decodeCompleteStop


decodeExistingStops : Decoder (List Stop)
decodeExistingStops =
    Json.Decode.at [ "data" ] (Json.Decode.list decodeExistingStop)


serializeStopAreas : Dict StopAreaId StopArea -> Body
serializeStopAreas stopAreas =
    Json.Encode.object [ ( "data", encodeStops <| chosenNewStops stopAreas ) ]
        |> jsonBody


chosenNewStops : Dict StopAreaId StopArea -> List CompleteStop
chosenNewStops stopAreas =
    let
        newCompleteStop stop =
            case stop of
                NewStop s ->
                    Just s

                ExistingStop s ->
                    Nothing
    in
        Dict.values stopAreas
            |> List.filterMap (\sa -> sa.chosen)
            |> List.filterMap (\s -> newCompleteStop s)


encodeStops : List CompleteStop -> Value
encodeStops ss =
    List.map encodeStop ss |> Json.Encode.list


encodeStop : CompleteStop -> Value
encodeStop s =
    Json.Encode.object
        [ ( "type", Json.Encode.string "stops" )
        , ( "id", Json.Encode.string s.id )
        , ( "attributes"
          , Json.Encode.object
                [ ( "name", Json.Encode.string s.name )
                , ( "latitude", Json.Encode.float s.latitude )
                , ( "longitude", Json.Encode.float s.longitude )
                ]
          )
        ]


saveStopsToServer : Body -> Cmd Msg
saveStopsToServer body =
    let
        path =
            "/api/location_collections"

        errorDecoder =
            Json.Decode.list (Json.Decode.dict Json.Decode.string)

        request =
            Http.post path body (Json.Decode.field "errors" errorDecoder)
    in
        Http.send SaveStopsResult request


noContentResponse : Result Http.Error (List (Dict String String)) -> Bool
noContentResponse result =
    case result of
        Ok _ ->
            False

        Err error ->
            case error of
                BadPayload _ response ->
                    String.isEmpty response.body

                otherwise ->
                    False
