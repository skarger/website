module Locations.Models
    exposing
        ( LocationId
        , LocationArea
        , LocationAreaId
        , LocationInput(..)
        , Location(..)
        , LocationAreaStatus(..)
        , CompleteLocation
        , Coordinates
        , extractLocationInputId
        , locationAttr
        , extractLocationId
        , toCompleteLocation
        , locationIsChosen
        )

import Dict exposing (Dict)


type alias LocationId =
    String


type LocationInput
    = Address LocationId String
    | LatLngFromUrl LocationId Float Float
    | LatLngFromMap LocationId Float Float


type alias LocationAreaId =
    Int


type LocationAreaStatus
    = Initialized
    | GeocodeFailure String
    | GeocodeSuccess
    | FetchingPossibleDuplicates
    | Invalid String
    | Valid


type alias LocationArea =
    { locationInput : LocationInput
    , status : LocationAreaStatus
    , locations : Dict LocationId Location
    , chosen : Maybe Location
    }


type alias Coordinates =
    { latitude : Float
    , longitude : Float
    }


type Location
    = NewLocation CompleteLocation
    | ExistingLocation CompleteLocation


type alias CompleteLocation =
    { id : LocationId
    , name : String
    , latitude : Float
    , longitude : Float
    , drawn : Bool
    }


extractLocationInputId : LocationInput -> LocationId
extractLocationInputId locationInput =
    case locationInput of
        Address id _ ->
            id

        LatLngFromUrl id _ _ ->
            id

        LatLngFromMap id _ _ ->
            id


locationAttr : (CompleteLocation -> a) -> Location -> a
locationAttr accessor location =
    case location of
        NewLocation s ->
            accessor s

        ExistingLocation s ->
            accessor s


extractLocationId : Location -> LocationId
extractLocationId location =
    case location of
        NewLocation s ->
            s.id

        ExistingLocation s ->
            s.id


toCompleteLocation : Location -> CompleteLocation
toCompleteLocation location =
    case location of
        NewLocation s ->
            s

        ExistingLocation s ->
            s


locationIsChosen : LocationArea -> Location -> Bool
locationIsChosen locationArea location =
    locationArea.chosen == Just location
