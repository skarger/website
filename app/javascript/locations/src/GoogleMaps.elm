port module GoogleMaps
    exposing
        ( drawMarker
        , focusMarker
        , unfocusMarker
        , updateMarkerTitle
        , newStop
        , existingStop
        , clearMarkers
        , doubleClickMap
        , MapPoint
        )

import Stops.Models exposing (Stop(..), StopId, CompleteStop, extractStopId, toCompleteStop)


type alias MapPoint =
    { id : StopId
    , latitude : Float
    , longitude : Float
    , name : String
    , markerType : String
    }


type alias MarkerTitle =
    { id : StopId
    , name : String
    }


newStop : String
newStop =
    "NEW_STOP"


existingStop : String
existingStop =
    "EXISTING_STOP"


drawMarker : String -> CompleteStop -> Cmd msg
drawMarker markerType stop =
    stopToMapPoint stop markerType |> draw


focusMarker : StopId -> Cmd msg
focusMarker stopId =
    focus stopId


unfocusMarker : StopId -> Cmd msg
unfocusMarker stopId =
    unfocus stopId


updateMarkerTitle : StopId -> String -> Cmd msg
updateMarkerTitle stopId stopName =
    updateTitle { id = stopId, name = stopName }


clearMarkers : List Stop -> Cmd msg
clearMarkers stops =
    List.map extractStopId stops |> clear


stopToMapPoint : CompleteStop -> String -> MapPoint
stopToMapPoint stop markerType =
    { id = stop.id
    , latitude = stop.latitude
    , longitude = stop.longitude
    , name = stop.name
    , markerType = markerType
    }


port draw : MapPoint -> Cmd msg


port focus : StopId -> Cmd msg


port unfocus : StopId -> Cmd msg


port updateTitle : MarkerTitle -> Cmd msg


port clear : List StopId -> Cmd msg


port doubleClickMap : (MapPoint -> msg) -> Sub msg
