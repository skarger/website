module Stops.AreaValidator
    exposing
        ( validate
        , allValid
        , validateStopArea
        )

import Dict exposing (Dict)
import Models exposing (Model)
import Stops.Models
    exposing
        ( StopArea
        , StopAreaId
        , Stop(..)
        , StopId
        , StopAreaStatus(..)
        , stopAttr
        )
import Stops.Stops as Stops


allValid : Model -> Bool
allValid model =
    Dict.values model.stopAreas
        |> List.map validateStopArea
        |> List.all ((==) Valid << .status)


validate : Model -> StopAreaId -> Model
validate model stopAreaId =
    let
        updateStatus =
            Maybe.map validateStopArea
    in
        Stops.updateStopArea model stopAreaId updateStatus


validateStopArea : StopArea -> StopArea
validateStopArea sa =
    case sa.chosen of
        Nothing ->
            ({ sa | status = Invalid "Please choose a location" })

        Just s ->
            let
                status =
                    if stopAttr .name s == "" then
                        Invalid "Location name cannot be empty"
                    else
                        Valid
            in
                ({ sa | status = status })
