module Locations.AreaValidator
    exposing
        ( validate
        , allValid
        , validateLocationArea
        )

import Dict exposing (Dict)
import Models exposing (Model)
import Locations.Models
    exposing
        ( LocationArea
        , LocationAreaId
        , Location(..)
        , LocationId
        , LocationAreaStatus(..)
        , locationAttr
        )
import Locations.Locations as Locations


allValid : Model -> Bool
allValid model =
    Dict.values model.locationAreas
        |> List.map validateLocationArea
        |> List.all ((==) Valid << .status)


validate : Model -> LocationAreaId -> Model
validate model locationAreaId =
    let
        updateStatus =
            Maybe.map validateLocationArea
    in
        Locations.updateLocationArea model locationAreaId updateStatus


validateLocationArea : LocationArea -> LocationArea
validateLocationArea la =
    case la.chosen of
        Nothing ->
            ({ la | status = Invalid "Please choose a location" })

        Just s ->
            let
                status =
                    if locationAttr .name s == "" then
                        Invalid "Location name cannot be empty"
                    else
                        Valid
            in
                ({ la | status = status })
