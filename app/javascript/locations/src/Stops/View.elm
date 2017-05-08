module Stops.View exposing (view)

import Html exposing (Html, node, div, span, text, img, input, button, h3)
import Html.Attributes exposing (id, src, class, value, style, title)
import Html.Events exposing (on, targetValue, onClick, onMouseOver, onMouseLeave)
import Json.Decode
import Dict exposing (Dict)
import Models exposing (Model, SaveStatus(..))
import Messages exposing (Msg(..))
import Stops.Models
    exposing
        ( StopInput(..)
        , StopArea
        , StopAreaId
        , Stop(..)
        , StopAreaStatus(..)
        , CompleteStop
        , toCompleteStop
        , stopIsChosen
        )
import Stops.AreaValidator as StopAreaValidator exposing (allValid)


view : Model -> List (Html Msg)
view model =
    if Dict.isEmpty model.stopAreas then
        []
    else
        [ div [ class "ui segments" ] (stopAreaRows model)
        , div [ class "ui hidden divider" ] []
        , div [ class "ui grid" ]
            [ div [ class "two column row" ]
                [ div [ class "left floated column" ]
                    [ button [ class "ui red button", onClick ClearStops ] [ text "Clear Locations" ]
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
            Dict.values model.stopAreas
                |> List.map .status
                |> List.any (flip List.member [ Initialized, FetchingPossibleDuplicates ])
    in
        case (unsteadyState model || StopAreaValidator.allValid model) of
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
        buttonClass =
            case ( model.saveStatus, StopAreaValidator.allValid model ) of
                ( Saving, _ ) ->
                    "ui blue right floated loading button"

                ( NotAttempted, True ) ->
                    "ui blue right floated button"

                ( Failure, True ) ->
                    "ui blue right floated button"

                otherwise ->
                    "ui blue disabled right floated button"
    in
        [ button
            [ class buttonClass, onClick SaveStops ]
            [ text "Save Locations" ]
        ]


stopAreaRows : Model -> List (Html Msg)
stopAreaRows model =
    let
        rowNumbers =
            List.range 1 (Dict.size model.stopAreas)
    in
        Dict.toList model.stopAreas
            |> List.sortBy (Tuple.first)
            |> List.map2 (,) rowNumbers
            |> List.map (\( row, ( idx, sa ) ) -> stopAreaRow model row idx sa)


stopAreaRow : Model -> Int -> StopAreaId -> StopArea -> Html Msg
stopAreaRow model rowNumber saId sa =
    case sa.status of
        Initialized ->
            waitingRow model rowNumber saId

        GeocodeFailure message ->
            geocodeFailureRow rowNumber saId sa message

        GeocodeSuccess ->
            stopAreaDataRow model rowNumber saId sa

        FetchingPossibleDuplicates ->
            waitingRow model rowNumber saId

        otherwise ->
            stopAreaDataRow model rowNumber saId sa


stopAreaDataRow : Model -> Int -> StopAreaId -> StopArea -> Html Msg
stopAreaDataRow model rowNumber stopAreaId stopArea =
    let
        ( es, ns ) =
            Dict.partition
                (\id s ->
                    case s of
                        ExistingStop s ->
                            True

                        otherwise ->
                            False
                )
                stopArea.stops

        newStop =
            Dict.values ns |> List.head

        existingStops =
            Dict.values es

        inputRow =
            case newStop of
                Just stop ->
                    [ newStopItem stopAreaId
                        stopArea
                        stop
                        (List.length existingStops > 0)
                    ]

                otherwise ->
                    []
    in
        stopAreaRowDiv rowNumber
            stopAreaId
            ((stopAreaTopRow stopArea)
                ++ stopAreaMainRow rowNumber
                    stopAreaId
                    [ div [ class "ui divided list" ] <|
                        (inputRow
                            ++ (possibleDuplicateList
                                    stopAreaId
                                    stopArea
                                    existingStops
                               )
                        )
                    ]
            )


stopAreaTopRow : StopArea -> List (Html Msg)
stopAreaTopRow stopArea =
    let
        messageLabel =
            case stopArea.status of
                Invalid message ->
                    [ errorMessage message ]

                otherwise ->
                    []
    in
        [ div [ class "two wide column" ] []
        , div [ class "fourteen wide column" ] messageLabel
        ]


stopAreaMainRow : Int -> StopAreaId -> List (Html Msg) -> List (Html Msg)
stopAreaMainRow rowNumber stopAreaId content =
    [ div [ class "one wide middle aligned center aligned column" ]
        [ button
            [ class "ui red tiny compact button"
            , onClick <| RemoveStopEntry stopAreaId
            ]
            [ text "X" ]
        ]
    , div [ class "one wide middle aligned center aligned column" ]
        [ h3 [ class "ui header" ] [ text <| toString <| rowNumber ] ]
    , div [ class "fourteen wide column" ] content
    ]


waitingRow : Model -> Int -> StopAreaId -> Html Msg
waitingRow model rowNumber stopAreaId =
    stopAreaRowDiv rowNumber stopAreaId [ waitingItem model ]


stopAreaRowDiv : Int -> StopAreaId -> List (Html Msg) -> Html Msg
stopAreaRowDiv rowNumber stopAreaId content =
    div [ class "ui padded blue segment", id (toString stopAreaId) ]
        [ div [ class "ui grid" ] content ]


waitingItem : Model -> Html Msg
waitingItem model =
    div [] [ img [ class "waiting", src model.waiting ] [] ]


chooseButton : StopAreaId -> CompleteStop -> Html Msg
chooseButton stopAreaId s =
    div [ class "right floated content" ]
        [ div [ class "small ui button", onClick (ChooseStop stopAreaId s.id) ]
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


stopItemAttributes : StopArea -> Stop -> List (Html.Attribute Msg)
stopItemAttributes stopArea stop =
    let
        alwaysFocus =
            [ class "item" ]

        mouseOverFocus s =
            [ class "item", onMouseOver (FocusStop s.id), onMouseLeave (UnfocusStop s.id) ]
    in
        case ( stopArea.chosen, stop ) of
            ( Nothing, NewStop s ) ->
                alwaysFocus

            ( Nothing, ExistingStop s ) ->
                mouseOverFocus s

            ( Just _, NewStop s ) ->
                case stopIsChosen stopArea stop of
                    True ->
                        alwaysFocus

                    False ->
                        mouseOverFocus s

            ( Just _, ExistingStop s ) ->
                case stopIsChosen stopArea stop of
                    True ->
                        alwaysFocus

                    False ->
                        mouseOverFocus s


stopItemClass : StopArea -> Stop -> String
stopItemClass stopArea stop =
    if stopIsChosen stopArea stop then
        "stop-item chosen-stop"
    else
        "stop-item"


onBlurWithTargetValue : (String -> msg) -> Html.Attribute msg
onBlurWithTargetValue tagger =
    on "blur" (Json.Decode.map tagger targetValue)


newStopItem : StopAreaId -> StopArea -> Stop -> Bool -> Html Msg
newStopItem stopAreaId stopArea stop possibleDuplicatesExist =
    let
        s =
            toCompleteStop stop

        stopInput =
            (div [ class ("ui input " ++ (stopItemClass stopArea stop)) ]
                [ input
                    [ class "stop-name"
                    , onBlurWithTargetValue (NameChanged stopAreaId s.id)
                    , value s.name
                    ]
                    []
                ]
            )

        content =
            -- right floated button needs to be before input to align correctly
            case possibleDuplicatesExist of
                False ->
                    [ spacerButton, stopInput ]

                True ->
                    [ chooseButton stopAreaId s, stopInput ]
    in
        div ([ id s.id ] ++ (stopItemAttributes stopArea stop)) content


possibleDuplicateList : StopAreaId -> StopArea -> List Stop -> List (Html Msg)
possibleDuplicateList stopAreaId stopArea pds =
    case List.isEmpty pds of
        True ->
            []

        False ->
            div [ class "ui sub header" ] [ text "Nearby Locations" ]
                :: List.map (possibleDuplicateItem stopAreaId stopArea) pds


possibleDuplicateItem : StopAreaId -> StopArea -> Stop -> Html Msg
possibleDuplicateItem stopAreaId stopArea pd =
    let
        cs =
            toCompleteStop pd
    in
        div
            ([ id cs.id ] ++ (stopItemAttributes stopArea pd))
            [ div [ class "right floated content" ] [ chooseButton stopAreaId cs ]
            , div [ class (stopItemClass stopArea pd) ] [ text cs.name ]
            ]


geocodeFailureRow : Int -> StopAreaId -> StopArea -> String -> Html Msg
geocodeFailureRow rowNumber stopAreaId stopArea err =
    let
        message =
            errorMessage err

        formatCoordinates lat lng =
            "( " ++ String.join ", " [ toString lat, toString lng ] ++ " )"

        ( name, stopId ) =
            case stopArea.stopInput of
                Address id a ->
                    ( a, id )

                PointFromUrl id lat lng ->
                    ( formatCoordinates lat lng, id )

                PointFromMap id lat lng ->
                    ( formatCoordinates lat lng, id )

        retryButton =
            div [ class "ui small button", onClick (RetryGeocoding stopAreaId) ] [ text "Retry" ]

        location =
            div [] [ text <| name ]
    in
        stopAreaRowDiv rowNumber
            stopAreaId
            (stopAreaMainRow rowNumber
                stopAreaId
                [ message
                , div [ class "ui divided list" ]
                    [ div [ id stopId, class "item" ]
                        [ div [ class "right floated content" ] [ retryButton ]
                        , location
                        ]
                    ]
                ]
            )
