module Messages exposing (Msg(..))

import Http
import Dict exposing (Dict)
import Geocoding
import Stops.Models exposing (StopAreaId, StopArea, StopId, Stop)
import GoogleMaps exposing (MapPoint)


type Msg
    = EnterUrl String
    | StopsGeocoderResult StopAreaId StopArea (Result Http.Error Geocoding.Response)
    | RetryGeocoding StopAreaId
    | NameChanged StopAreaId StopId String
    | DoubleClickMap MapPoint
    | PossibleDuplicateStops StopAreaId (Result Http.Error (List Stop))
    | FocusStop StopId
    | UnfocusStop StopId
    | ChooseStop StopAreaId StopId
    | ClearStops
    | SaveStops
    | SaveStopsResult (Result Http.Error (List (Dict String String)))
    | RemoveStopEntry StopAreaId
