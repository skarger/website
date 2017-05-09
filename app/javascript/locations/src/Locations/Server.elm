module Locations.Server exposing (fetchPossibleDuplicates, serializeLocationAreas, saveLocationsToServer, noContentResponse)

import Http exposing (Body, Error(..), jsonBody)
import Json.Decode exposing (Decoder, at)
import Json.Decode.Pipeline exposing (decode, required, requiredAt, hardcoded)
import Json.Encode exposing (Value)
import Dict exposing (Dict)
import Messages exposing (Msg(..))
import Locations.Models exposing (CompleteLocation, Location(..), LocationAreaId, LocationArea)


fetchPossibleDuplicates : LocationAreaId -> CompleteLocation -> Cmd Msg
fetchPossibleDuplicates locationAreaId location =
    let
        latitude =
            location.latitude

        longitude =
            location.longitude

        path =
            "/api/nearby_locations"

        query =
            queryString
                [ ( "latitude", toString latitude )
                , ( "longitude", toString longitude )
                ]

        request =
            Http.get (path ++ query) decodeExistingLocations
    in
        Http.send (PossibleDuplicateLocations locationAreaId) request


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


decodeCompleteLocation : Decoder CompleteLocation
decodeCompleteLocation =
    let
        drawn =
            False
    in
        decode CompleteLocation
            |> required "id" Json.Decode.string
            |> requiredAt [ "attributes" ] (Json.Decode.field "name" Json.Decode.string)
            |> requiredAt [ "attributes" ] (Json.Decode.field "latitude" Json.Decode.float)
            |> requiredAt [ "attributes" ] (Json.Decode.field "longitude" Json.Decode.float)
            |> hardcoded drawn


decodeExistingLocation : Decoder Location
decodeExistingLocation =
    Json.Decode.map ExistingLocation decodeCompleteLocation


decodeExistingLocations : Decoder (List Location)
decodeExistingLocations =
    Json.Decode.at [ "data" ] (Json.Decode.list decodeExistingLocation)


serializeLocationAreas : Dict LocationAreaId LocationArea -> Body
serializeLocationAreas locationAreas =
    Json.Encode.object [ ( "data", encodeLocations <| chosenNewLocations locationAreas ) ]
        |> jsonBody


chosenNewLocations : Dict LocationAreaId LocationArea -> List CompleteLocation
chosenNewLocations locationAreas =
    let
        newCompleteLocation location =
            case location of
                NewLocation s ->
                    Just s

                ExistingLocation s ->
                    Nothing
    in
        Dict.values locationAreas
            |> List.filterMap (\sa -> sa.chosen)
            |> List.filterMap (\s -> newCompleteLocation s)


encodeLocations : List CompleteLocation -> Value
encodeLocations ss =
    List.map encodeLocation ss |> Json.Encode.list


encodeLocation : CompleteLocation -> Value
encodeLocation s =
    Json.Encode.object
        [ ( "type", Json.Encode.string "locations" )
        , ( "id", Json.Encode.string s.id )
        , ( "attributes"
          , Json.Encode.object
                [ ( "name", Json.Encode.string s.name )
                , ( "latitude", Json.Encode.float s.latitude )
                , ( "longitude", Json.Encode.float s.longitude )
                ]
          )
        ]


saveLocationsToServer : Body -> Cmd Msg
saveLocationsToServer body =
    let
        path =
            "/api/location_collections"

        errorDecoder =
            Json.Decode.list (Json.Decode.dict Json.Decode.string)

        request =
            Http.post path body (Json.Decode.field "errors" errorDecoder)
    in
        Http.send SaveLocationsResult request


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
