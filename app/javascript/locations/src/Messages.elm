module Messages exposing (Msg(..))

import Http
import Dict exposing (Dict)
import Geocoding
import Locations.Models exposing (LocationAreaId, LocationArea, LocationId, Location)
import GoogleMaps exposing (MapPoint)


type Msg
    = EnterUrl String
    | LocationsGeocoderResult LocationAreaId LocationArea (Result Http.Error Geocoding.Response)
    | RetryGeocoding LocationAreaId
    | NameChanged LocationAreaId LocationId String
    | DoubleClickMap MapPoint
    | PossibleDuplicateLocations LocationAreaId (Result Http.Error (List Location))
    | FocusLocation LocationId
    | UnfocusLocation LocationId
    | ChooseLocation LocationAreaId LocationId
    | ClearLocations
    | SaveLocations
    | SaveLocationsResult (Result Http.Error (List (Dict String String)))
    | RemoveLocationEntry LocationAreaId
