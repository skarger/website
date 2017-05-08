module Models exposing (Model, emptyModel, SaveStatus(..))

import Dict exposing (Dict)
import Stops.Models exposing (StopAreaId, StopArea)
import Random.Pcg exposing (Seed)


type alias Url =
    String


type alias StopEntry =
    String


type alias LineNumber =
    Int


type SaveStatus
    = NotAttempted
    | Saving
    | Failure
    | Success


type alias Model =
    { url : Url
    , stopAreas : Dict StopAreaId StopArea
    , error : String
    , waiting : String
    , stopAreaIndex : Int
    , currentSeed : Seed
    , saveStatus : SaveStatus
    }


emptyModel : String -> Seed -> Model
emptyModel waiting randomSeed =
    { url = ""
    , stopAreas = Dict.empty
    , error = ""
    , waiting = waiting
    , stopAreaIndex = 0
    , currentSeed = randomSeed
    , saveStatus = NotAttempted
    }
