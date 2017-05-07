module Stops.Stops
    exposing
        ( initializeStopArea
        , afterSuccessfulGeocode
        , drawPossibleDuplicates
        , updateStopName
        , appendPossibleDuplicates
        , removeStopArea
        , updateStopChosen
        , updateStopArea
        , refocusStopArea
        , overwriteWith
        )

import Dict exposing (Dict)
import Models exposing (Model)
import GoogleMaps
    exposing
        ( drawMarker
        , newStop
        , existingStop
        , focusMarker
        , unfocusMarker
        )
import Messages exposing (Msg(..))
import Stops.Models
    exposing
        ( StopInput(..)
        , StopArea
        , StopAreaId
        , Stop(..)
        , CompleteStop
        , StopAreaStatus(..)
        , StopId
        , Coordinates
        , extractStopInputId
        , extractStopId
        , toCompleteStop
        )
import Stops.Server exposing (fetchPossibleDuplicates)


initializeStopArea : StopInput -> StopArea
initializeStopArea stopInput =
    { stopInput = stopInput
    , status = Initialized
    , stops = Dict.empty
    , chosen = Nothing
    }


afterSuccessfulGeocode :
    Model
    -> StopAreaId
    -> StopArea
    -> CompleteStop
    -> ( Model, Cmd Msg )
afterSuccessfulGeocode model stopAreaId stopArea stop =
    let
        ( markerCmd, fetchCmd ) =
            ( if stop.drawn then
                GoogleMaps.updateMarkerTitle stop.id stop.name
              else
                drawMarker newStop stop
            , fetchPossibleDuplicates stopAreaId stop
            )

        drawnModel =
            updateStopDrawn True model stopAreaId stop.id
    in
        ( updateStopArea drawnModel
            stopAreaId
            (overwriteWith
                { stopArea | status = FetchingPossibleDuplicates }
            )
        , Cmd.batch [ markerCmd, fetchCmd ]
        )


appendPossibleDuplicates : List Stop -> Model -> StopAreaId -> Model
appendPossibleDuplicates pds model stopAreaId =
    let
        stopArea =
            Dict.get stopAreaId model.stopAreas

        newStopId =
            Maybe.map (extractStopInputId << .stopInput) stopArea
    in
        case ( stopArea, newStopId ) of
            ( Just sa, Just id ) ->
                let
                    updatedModel =
                        updatePossibleDuplicates pds model stopAreaId sa
                in
                    case List.length pds of
                        0 ->
                            updateStopChosen updatedModel stopAreaId id

                        otherwise ->
                            updatedModel

            otherwise ->
                model


updatePossibleDuplicates : List Stop -> Model -> StopAreaId -> StopArea -> Model
updatePossibleDuplicates dupes model stopAreaId stopArea =
    let
        keys =
            List.map extractStopId dupes

        kvs =
            List.map2 (,) keys dupes

        updatedStops =
            Dict.union (Dict.fromList kvs) stopArea.stops
    in
        updateStopArea model
            stopAreaId
            (overwriteWith
                { stopArea | stops = updatedStops }
            )


drawPossibleDuplicates : List Stop -> Cmd msg
drawPossibleDuplicates pds =
    List.map (drawMarker existingStop << toCompleteStop) pds
        |> Cmd.batch


refocusStopArea : Model -> StopAreaId -> StopId -> Cmd msg
refocusStopArea model stopAreaId chosenStopId =
    let
        stopArea =
            Dict.get stopAreaId model.stopAreas

        extractUnchosen chosenStopId stopArea =
            List.filter ((/=) chosenStopId) << Dict.keys << .stops <| stopArea

        unchosenStops =
            Maybe.withDefault [] <| Maybe.map (extractUnchosen chosenStopId) stopArea
    in
        List.map GoogleMaps.focusMarker [ chosenStopId ]
            ++ List.map GoogleMaps.unfocusMarker unchosenStops
            |> Cmd.batch


removeStopArea : Model -> StopAreaId -> ( Model, Cmd msg )
removeStopArea model stopAreaId =
    let
        cmd =
            Dict.get stopAreaId model.stopAreas
                |> Maybe.map (Dict.values << .stops)
                |> Maybe.map (\stops -> GoogleMaps.clearMarkers stops)
                |> Maybe.withDefault Cmd.none
    in
        ( { model | stopAreas = Dict.remove stopAreaId model.stopAreas }, cmd )


updateStopName : String -> (Model -> StopAreaId -> StopId -> Model)
updateStopName name =
    updateStop (\cs -> { cs | name = name })


updateStopDrawn : Bool -> (Model -> StopAreaId -> StopId -> Model)
updateStopDrawn drawn =
    updateStop (\cs -> { cs | drawn = drawn })


updateStopChosen : Model -> StopAreaId -> StopId -> Model
updateStopChosen model stopAreaId stopId =
    let
        stopArea =
            Dict.get stopAreaId model.stopAreas

        newChosenStop =
            Maybe.map .stops stopArea
                |> Maybe.andThen (Dict.get stopId)
    in
        case stopArea of
            Just sa ->
                updateStopArea
                    model
                    stopAreaId
                    (overwriteWith { sa | chosen = newChosenStop })

            Nothing ->
                model


updateStop : (CompleteStop -> CompleteStop) -> (Model -> StopAreaId -> StopId -> Model)
updateStop updater =
    \model stopAreaId stopId ->
        (case Dict.get stopAreaId model.stopAreas of
            Just sa ->
                let
                    modelWithStopUpdated =
                        updateStopArea
                            model
                            stopAreaId
                            ((updateStopAttribute updater sa stopId) |> overwriteWith)
                in
                    replicateChangeToChosen modelWithStopUpdated stopAreaId sa stopId

            Nothing ->
                model
        )


replicateChangeToChosen : Model -> StopAreaId -> StopArea -> StopId -> Model
replicateChangeToChosen model stopAreaId stopArea stopId =
    Maybe.map
        (\chosenStop ->
            if extractStopId chosenStop == stopId then
                updateStopChosen model stopAreaId stopId
            else
                model
        )
        stopArea.chosen
        |> Maybe.withDefault model


updateStopArea :
    Model
    -> StopAreaId
    -> (Maybe StopArea -> Maybe StopArea)
    -> Model
updateStopArea model stopAreaId stopAreaUpdater =
    { model | stopAreas = Dict.update stopAreaId stopAreaUpdater model.stopAreas }


updateStopAttribute : (CompleteStop -> CompleteStop) -> StopArea -> StopId -> StopArea
updateStopAttribute updateRecord stopArea stopId =
    case Dict.get stopId stopArea.stops of
        Nothing ->
            stopArea

        Just stop ->
            let
                updatedStop =
                    case stop of
                        NewStop ns ->
                            NewStop (updateRecord ns)

                        ExistingStop es ->
                            ExistingStop (updateRecord es)
            in
                setStop
                    (overwriteWith updatedStop)
                    stopArea
                    stopId


setStop : (Maybe Stop -> Maybe Stop) -> StopArea -> StopId -> StopArea
setStop stopUpdater stopArea stopId =
    { stopArea | stops = Dict.update stopId stopUpdater stopArea.stops }


overwriteWith : a -> (Maybe a -> Maybe a)
overwriteWith value =
    Maybe.map (always value)
