module Stops.Models
    exposing
        ( StopId
        , StopArea
        , StopAreaId
        , StopInput(..)
        , Stop(..)
        , StopAreaStatus(..)
        , CompleteStop
        , Coordinates
        , extractStopInputId
        , stopAttr
        , extractStopId
        , toCompleteStop
        , stopIsChosen
        )

import Dict exposing (Dict)


type alias StopId =
    String


type StopInput
    = Address StopId String
    | PointFromUrl StopId Float Float
    | PointFromMap StopId Float Float


type alias StopAreaId =
    Int


type StopAreaStatus
    = Initialized
    | GeocodeFailure String
    | GeocodeSuccess
    | FetchingPossibleDuplicates
    | Invalid String
    | Valid


type alias StopArea =
    { stopInput : StopInput
    , status : StopAreaStatus
    , stops : Dict StopId Stop
    , chosen : Maybe Stop
    }


type alias Coordinates =
    { latitude : Float
    , longitude : Float
    }


type Stop
    = NewStop CompleteStop
    | ExistingStop CompleteStop


type alias CompleteStop =
    { id : StopId
    , name : String
    , latitude : Float
    , longitude : Float
    , drawn : Bool
    }


extractStopInputId : StopInput -> StopId
extractStopInputId stopInput =
    case stopInput of
        Address id _ ->
            id

        PointFromUrl id _ _ ->
            id

        PointFromMap id _ _ ->
            id


stopAttr : (CompleteStop -> a) -> Stop -> a
stopAttr accessor stop =
    case stop of
        NewStop s ->
            accessor s

        ExistingStop s ->
            accessor s


extractStopId : Stop -> StopId
extractStopId stop =
    case stop of
        NewStop s ->
            s.id

        ExistingStop s ->
            s.id


toCompleteStop : Stop -> CompleteStop
toCompleteStop stop =
    case stop of
        NewStop s ->
            s

        ExistingStop s ->
            s


stopIsChosen : StopArea -> Stop -> Bool
stopIsChosen stopArea stop =
    stopArea.chosen == Just stop
