module Locations.View exposing (view)

import Html exposing (Html, node, div, span, text, img, input, button, h3)
import Html.Attributes exposing (id, src, class, value, style, title)
import Html.Events exposing (on, targetValue, onClick, onMouseOver, onMouseLeave)
import Json.Decode
import Dict exposing (Dict)
import Models exposing (Model, SaveStatus(..))
import Messages exposing (Msg(..))
import Locations.Models
    exposing
        ( LocationInput(..)
        , LocationArea
        , LocationAreaId
        , Location(..)
        , LocationAreaStatus(..)
        , CompleteLocation
        , toCompleteLocation
        , locationIsChosen
        )
import Locations.AreaValidator as LocationAreaValidator exposing (allValid)
import Locations.Locations as Locations


view : Model -> List (Html Msg)
view model =
    if Dict.isEmpty model.locationAreas then
        []
    else
        [ div [ class "ui segments" ] (locationAreaRows model)
        , div [ class "ui hidden divider" ] []
        , div [ class "ui grid" ]
            [ div [ class "two column row" ]
                [ div [ class "left floated column" ]
                    [ button [ class "ui red button", onClick ClearLocations ] [ text "Clear Locations" ]
                    ]
                , div [ class "right floated column" ] (saveButton model)
                ]
            , div [ class "two column row" ]
                [ div [ class "right floated column" ] (saveButtonLabel model)
                ]
            ]
        ]


saveButtonLabel : Model -> List (Html Msg)
saveButtonLabel model =
    let
        unsteadyState model =
            Dict.values model.locationAreas
                |> List.map .status
                |> List.any (flip List.member [ Initialized, FetchingPossibleDuplicates ])
    in
        case (unsteadyState model || LocationAreaValidator.allValid model) of
            True ->
                case model.saveStatus of
                    Failure ->
                        [ div [ class "ui red basic large label", style [ ( "float", "right" ) ] ]
                            [ text "Save failed. Try again and/or edit locations." ]
                        ]

                    Success ->
                        [ div [ class "ui blue basic large label", style [ ( "float", "right" ) ] ]
                            [ text "Saved locations" ]
                        ]

                    otherwise ->
                        []

            False ->
                [ div [ class "ui red basic large label", style [ ( "float", "right" ) ] ]
                    [ text "Please address errors" ]
                ]


saveButton : Model -> List (Html Msg)
saveButton model =
    let
        newLocationCount =
            Locations.chosenNewLocations model.locationAreas
                |> List.length

        buttonClass =
            case
                ( model.saveStatus
                , LocationAreaValidator.allValid model
                , newLocationCount > 0
                )
            of
                ( Saving, _, _ ) ->
                    "ui blue right floated loading button"

                ( NotAttempted, True, True ) ->
                    "ui blue right floated button"

                ( Failure, True, True ) ->
                    "ui blue right floated button"

                otherwise ->
                    "ui blue disabled right floated button"
    in
        [ button
            [ class buttonClass, onClick SaveLocations ]
            [ text "Save Locations" ]
        ]


locationAreaRows : Model -> List (Html Msg)
locationAreaRows model =
    let
        rowNumbers =
            List.range 1 (Dict.size model.locationAreas)
    in
        Dict.toList model.locationAreas
            |> List.sortBy (Tuple.first)
            |> List.map2 (,) rowNumbers
            |> List.map (\( row, ( idx, la ) ) -> locationAreaRow model row idx la)


locationAreaRow : Model -> Int -> LocationAreaId -> LocationArea -> Html Msg
locationAreaRow model rowNumber laId la =
    case la.status of
        Initialized ->
            waitingRow model rowNumber laId

        GeocodeFailure message ->
            geocodeFailureRow rowNumber laId la message

        GeocodeSuccess ->
            locationAreaDataRow model rowNumber laId la

        FetchingPossibleDuplicates ->
            waitingRow model rowNumber laId

        otherwise ->
            locationAreaDataRow model rowNumber laId la


locationAreaDataRow : Model -> Int -> LocationAreaId -> LocationArea -> Html Msg
locationAreaDataRow model rowNumber locationAreaId locationArea =
    let
        ( es, ns ) =
            Dict.partition
                (\id s ->
                    case s of
                        ExistingLocation s ->
                            True

                        otherwise ->
                            False
                )
                locationArea.locations

        newLocation =
            Dict.values ns |> List.head

        existingLocations =
            Dict.values es

        inputRow =
            case newLocation of
                Just location ->
                    [ newLocationItem locationAreaId
                        locationArea
                        location
                        (List.length existingLocations > 0)
                    ]

                otherwise ->
                    []
    in
        locationAreaRowDiv rowNumber
            locationAreaId
            ((locationAreaTopRow locationArea)
                ++ locationAreaMainRow rowNumber
                    locationAreaId
                    [ div [ class "ui divided list" ] <|
                        (inputRow
                            ++ (possibleDuplicateList
                                    locationAreaId
                                    locationArea
                                    existingLocations
                               )
                        )
                    ]
            )


locationAreaTopRow : LocationArea -> List (Html Msg)
locationAreaTopRow locationArea =
    let
        messageLabel =
            case locationArea.status of
                Invalid message ->
                    [ errorMessage message ]

                otherwise ->
                    []
    in
        [ div [ class "two wide column" ] []
        , div [ class "fourteen wide column" ] messageLabel
        ]


locationAreaMainRow : Int -> LocationAreaId -> List (Html Msg) -> List (Html Msg)
locationAreaMainRow rowNumber locationAreaId content =
    [ div [ class "one wide middle aligned center aligned column" ]
        [ button
            [ class "ui red tiny compact button"
            , onClick <| RemoveLocationEntry locationAreaId
            ]
            [ text "X" ]
        ]
    , div [ class "one wide middle aligned center aligned column" ]
        [ h3 [ class "ui header" ] [ text <| toString <| rowNumber ] ]
    , div [ class "fourteen wide column" ] content
    ]


waitingRow : Model -> Int -> LocationAreaId -> Html Msg
waitingRow model rowNumber locationAreaId =
    locationAreaRowDiv rowNumber locationAreaId [ waitingItem model ]


locationAreaRowDiv : Int -> LocationAreaId -> List (Html Msg) -> Html Msg
locationAreaRowDiv rowNumber locationAreaId content =
    div [ class "ui padded blue segment", id (toString locationAreaId) ]
        [ div [ class "ui grid" ] content ]


waitingItem : Model -> Html Msg
waitingItem model =
    div [] [ img [ class "waiting", src model.waiting ] [] ]


chooseButton : LocationAreaId -> CompleteLocation -> Html Msg
chooseButton locationAreaId s =
    div [ class "right floated content" ]
        [ div [ class "small ui button", onClick (ChooseLocation locationAreaId s.id) ]
            [ text "Choose" ]
        ]


spacerButton : Html Msg
spacerButton =
    div [ class "right floated content" ]
        [ div [ class "small ui disabled button spacer-button" ]
            [ text "Choose" ]
        ]


errorMessage : String -> Html Msg
errorMessage err =
    div [ class "ui red large basic label" ] [ text err ]


locationItemAttributes : LocationArea -> Location -> List (Html.Attribute Msg)
locationItemAttributes locationArea location =
    let
        alwaysFocus =
            [ class "item" ]

        mouseOverFocus s =
            [ class "item", onMouseOver (FocusLocation s.id), onMouseLeave (UnfocusLocation s.id) ]
    in
        case ( locationArea.chosen, location ) of
            ( Nothing, NewLocation s ) ->
                alwaysFocus

            ( Nothing, ExistingLocation s ) ->
                mouseOverFocus s

            ( Just _, NewLocation s ) ->
                case locationIsChosen locationArea location of
                    True ->
                        alwaysFocus

                    False ->
                        mouseOverFocus s

            ( Just _, ExistingLocation s ) ->
                case locationIsChosen locationArea location of
                    True ->
                        alwaysFocus

                    False ->
                        mouseOverFocus s


locationItemClass : LocationArea -> Location -> String
locationItemClass locationArea location =
    if locationIsChosen locationArea location then
        "location-item chosen-location"
    else
        "location-item"


onBlurWithTargetValue : (String -> msg) -> Html.Attribute msg
onBlurWithTargetValue tagger =
    on "blur" (Json.Decode.map tagger targetValue)


newLocationItem : LocationAreaId -> LocationArea -> Location -> Bool -> Html Msg
newLocationItem locationAreaId locationArea location possibleDuplicatesExist =
    let
        s =
            toCompleteLocation location

        locationInput =
            (div [ class ("ui input " ++ (locationItemClass locationArea location)) ]
                [ input
                    [ class "location-name"
                    , onBlurWithTargetValue (NameChanged locationAreaId s.id)
                    , value s.name
                    ]
                    []
                ]
            )

        content =
            -- right floated button needs to be before input to align correctly
            case possibleDuplicatesExist of
                False ->
                    [ spacerButton, locationInput ]

                True ->
                    [ chooseButton locationAreaId s, locationInput ]
    in
        div ([ id s.id ] ++ (locationItemAttributes locationArea location)) content


possibleDuplicateList : LocationAreaId -> LocationArea -> List Location -> List (Html Msg)
possibleDuplicateList locationAreaId locationArea pds =
    case List.isEmpty pds of
        True ->
            []

        False ->
            div [ class "ui sub header" ] [ text "Nearby Locations" ]
                :: List.map (possibleDuplicateItem locationAreaId locationArea) pds


possibleDuplicateItem : LocationAreaId -> LocationArea -> Location -> Html Msg
possibleDuplicateItem locationAreaId locationArea pd =
    let
        cs =
            toCompleteLocation pd
    in
        div
            ([ id cs.id ] ++ (locationItemAttributes locationArea pd))
            [ div [ class "right floated content" ] [ chooseButton locationAreaId cs ]
            , div [ class (locationItemClass locationArea pd) ] [ text cs.name ]
            ]


geocodeFailureRow : Int -> LocationAreaId -> LocationArea -> String -> Html Msg
geocodeFailureRow rowNumber locationAreaId locationArea err =
    let
        message =
            errorMessage err

        formatCoordinates lat lng =
            "( " ++ String.join ", " [ toString lat, toString lng ] ++ " )"

        ( name, locationId ) =
            case locationArea.locationInput of
                Address id a ->
                    ( a, id )

                LatLngFromUrl id lat lng ->
                    ( formatCoordinates lat lng, id )

                LatLngFromMap id lat lng ->
                    ( formatCoordinates lat lng, id )

        retryButton =
            div [ class "ui small button", onClick (RetryGeocoding locationAreaId) ] [ text "Retry" ]

        enteredPoint =
            div [] [ text <| name ]
    in
        locationAreaRowDiv rowNumber
            locationAreaId
            (locationAreaMainRow rowNumber
                locationAreaId
                [ message
                , div [ class "ui divided list" ]
                    [ div [ id locationId, class "item" ]
                        [ div [ class "right floated content" ] [ retryButton ]
                        , enteredPoint
                        ]
                    ]
                ]
            )
