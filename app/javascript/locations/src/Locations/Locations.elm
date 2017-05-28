module Locations.Locations
    exposing
        ( initializeLocationArea
        , afterSuccessfulGeocode
        , drawPossibleDuplicates
        , updateLocationName
        , appendPossibleDuplicates
        , chosenNewLocations
        , removeLocationArea
        , updateLocationChosen
        , updateLocationArea
        , refocusLocationArea
        , overwriteWith
        )

import Dict exposing (Dict)
import Models exposing (Model)
import GoogleMaps
    exposing
        ( drawMarker
        , newLocation
        , existingLocation
        , focusMarker
        , unfocusMarker
        )
import Messages exposing (Msg(..))
import Locations.Models
    exposing
        ( LocationInput(..)
        , LocationArea
        , LocationAreaId
        , Location(..)
        , CompleteLocation
        , LocationAreaStatus(..)
        , LocationId
        , Coordinates
        , extractLocationInputId
        , extractLocationId
        , toCompleteLocation
        )
import Locations.Server exposing (fetchPossibleDuplicates)


initializeLocationArea : LocationInput -> LocationArea
initializeLocationArea locationInput =
    { locationInput = locationInput
    , status = Initialized
    , locations = Dict.empty
    , chosen = Nothing
    }


afterSuccessfulGeocode :
    Model
    -> LocationAreaId
    -> LocationArea
    -> CompleteLocation
    -> ( Model, Cmd Msg )
afterSuccessfulGeocode model locationAreaId locationArea location =
    let
        ( markerCmd, fetchCmd ) =
            ( if location.drawn then
                GoogleMaps.updateMarkerTitle location.id location.name
              else
                drawMarker newLocation location
            , fetchPossibleDuplicates locationAreaId location
            )

        drawnModel =
            updateLocationDrawn True model locationAreaId location.id
    in
        ( updateLocationArea drawnModel
            locationAreaId
            (overwriteWith
                { locationArea | status = FetchingPossibleDuplicates }
            )
        , Cmd.batch [ markerCmd, fetchCmd ]
        )


appendPossibleDuplicates : List Location -> Model -> LocationAreaId -> Model
appendPossibleDuplicates pds model locationAreaId =
    let
        locationArea =
            Dict.get locationAreaId model.locationAreas

        newLocationId =
            Maybe.map (extractLocationInputId << .locationInput) locationArea
    in
        case ( locationArea, newLocationId ) of
            ( Just sa, Just id ) ->
                let
                    updatedModel =
                        updatePossibleDuplicates pds model locationAreaId sa
                in
                    case List.length pds of
                        0 ->
                            updateLocationChosen updatedModel locationAreaId id

                        otherwise ->
                            updatedModel

            otherwise ->
                model


updatePossibleDuplicates : List Location -> Model -> LocationAreaId -> LocationArea -> Model
updatePossibleDuplicates dupes model locationAreaId locationArea =
    let
        keys =
            List.map extractLocationId dupes

        kvs =
            List.map2 (,) keys dupes

        updatedLocations =
            Dict.union (Dict.fromList kvs) locationArea.locations
    in
        updateLocationArea model
            locationAreaId
            (overwriteWith
                { locationArea | locations = updatedLocations }
            )


drawPossibleDuplicates : List Location -> Cmd msg
drawPossibleDuplicates pds =
    List.map (drawMarker existingLocation << toCompleteLocation) pds
        |> Cmd.batch


refocusLocationArea : Model -> LocationAreaId -> LocationId -> Cmd msg
refocusLocationArea model locationAreaId chosenLocationId =
    let
        locationArea =
            Dict.get locationAreaId model.locationAreas

        extractUnchosen chosenLocationId locationArea =
            List.filter ((/=) chosenLocationId) << Dict.keys << .locations <| locationArea

        unchosenLocations =
            Maybe.withDefault [] <| Maybe.map (extractUnchosen chosenLocationId) locationArea
    in
        List.map GoogleMaps.focusMarker [ chosenLocationId ]
            ++ List.map GoogleMaps.unfocusMarker unchosenLocations
            |> Cmd.batch


chosenNewLocations : Dict LocationAreaId LocationArea -> List CompleteLocation
chosenNewLocations locationAreas =
    let
        newCompleteLocation location =
            case location of
                NewLocation l ->
                    Just l

                ExistingLocation l ->
                    Nothing
    in
        Dict.values locationAreas
            |> List.filterMap (\la -> la.chosen)
            |> List.filterMap (\l -> newCompleteLocation l)


removeLocationArea : Model -> LocationAreaId -> ( Model, Cmd msg )
removeLocationArea model locationAreaId =
    let
        cmd =
            Dict.get locationAreaId model.locationAreas
                |> Maybe.map (Dict.values << .locations)
                |> Maybe.map (\locations -> GoogleMaps.clearMarkers locations)
                |> Maybe.withDefault Cmd.none
    in
        ( { model | locationAreas = Dict.remove locationAreaId model.locationAreas }, cmd )


updateLocationName : String -> (Model -> LocationAreaId -> LocationId -> Model)
updateLocationName name =
    updateLocation (\cs -> { cs | name = name })


updateLocationDrawn : Bool -> (Model -> LocationAreaId -> LocationId -> Model)
updateLocationDrawn drawn =
    updateLocation (\cs -> { cs | drawn = drawn })


updateLocationChosen : Model -> LocationAreaId -> LocationId -> Model
updateLocationChosen model locationAreaId locationId =
    let
        locationArea =
            Dict.get locationAreaId model.locationAreas

        newChosenLocation =
            Maybe.map .locations locationArea
                |> Maybe.andThen (Dict.get locationId)
    in
        case locationArea of
            Just sa ->
                updateLocationArea
                    model
                    locationAreaId
                    (overwriteWith { sa | chosen = newChosenLocation })

            Nothing ->
                model


updateLocation : (CompleteLocation -> CompleteLocation) -> (Model -> LocationAreaId -> LocationId -> Model)
updateLocation updater =
    \model locationAreaId locationId ->
        (case Dict.get locationAreaId model.locationAreas of
            Just sa ->
                let
                    modelWithLocationUpdated =
                        updateLocationArea
                            model
                            locationAreaId
                            ((updateLocationAttribute updater sa locationId) |> overwriteWith)
                in
                    replicateChangeToChosen modelWithLocationUpdated locationAreaId sa locationId

            Nothing ->
                model
        )


replicateChangeToChosen : Model -> LocationAreaId -> LocationArea -> LocationId -> Model
replicateChangeToChosen model locationAreaId locationArea locationId =
    Maybe.map
        (\chosenLocation ->
            if extractLocationId chosenLocation == locationId then
                updateLocationChosen model locationAreaId locationId
            else
                model
        )
        locationArea.chosen
        |> Maybe.withDefault model


updateLocationArea :
    Model
    -> LocationAreaId
    -> (Maybe LocationArea -> Maybe LocationArea)
    -> Model
updateLocationArea model locationAreaId locationAreaUpdater =
    { model | locationAreas = Dict.update locationAreaId locationAreaUpdater model.locationAreas }


updateLocationAttribute : (CompleteLocation -> CompleteLocation) -> LocationArea -> LocationId -> LocationArea
updateLocationAttribute updateRecord locationArea locationId =
    case Dict.get locationId locationArea.locations of
        Nothing ->
            locationArea

        Just location ->
            let
                updatedLocation =
                    case location of
                        NewLocation ns ->
                            NewLocation (updateRecord ns)

                        ExistingLocation es ->
                            ExistingLocation (updateRecord es)
            in
                setLocation
                    (overwriteWith updatedLocation)
                    locationArea
                    locationId


setLocation : (Maybe Location -> Maybe Location) -> LocationArea -> LocationId -> LocationArea
setLocation locationUpdater locationArea locationId =
    { locationArea | locations = Dict.update locationId locationUpdater locationArea.locations }


overwriteWith : a -> (Maybe a -> Maybe a)
overwriteWith value =
    Maybe.map (always value)
