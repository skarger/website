port module GoogleMaps
    exposing
        ( drawMarker
        , focusMarker
        , unfocusMarker
        , updateMarkerTitle
        , newLocation
        , existingLocation
        , clearMarkers
        , doubleClickMap
        , MapPoint
        )

import Locations.Models exposing (Location(..), LocationId, CompleteLocation, extractLocationId, toCompleteLocation)


type alias MapPoint =
    { id : LocationId
    , latitude : Float
    , longitude : Float
    , name : String
    , markerType : String
    }


type alias MarkerTitle =
    { id : LocationId
    , name : String
    }


newLocation : String
newLocation =
    "NEW_LOCATION"


existingLocation : String
existingLocation =
    "EXISTING_LOCATION"


drawMarker : String -> CompleteLocation -> Cmd msg
drawMarker markerType location =
    locationToMapPoint location markerType |> draw


focusMarker : LocationId -> Cmd msg
focusMarker locationId =
    focus locationId


unfocusMarker : LocationId -> Cmd msg
unfocusMarker locationId =
    unfocus locationId


updateMarkerTitle : LocationId -> String -> Cmd msg
updateMarkerTitle locationId locationName =
    updateTitle { id = locationId, name = locationName }


clearMarkers : List Location -> Cmd msg
clearMarkers locations =
    List.map extractLocationId locations |> clear


locationToMapPoint : CompleteLocation -> String -> MapPoint
locationToMapPoint location markerType =
    { id = location.id
    , latitude = location.latitude
    , longitude = location.longitude
    , name = location.name
    , markerType = markerType
    }


port draw : MapPoint -> Cmd msg


port focus : LocationId -> Cmd msg


port unfocus : LocationId -> Cmd msg


port updateTitle : MarkerTitle -> Cmd msg


port clear : List LocationId -> Cmd msg


port doubleClickMap : (MapPoint -> msg) -> Sub msg
