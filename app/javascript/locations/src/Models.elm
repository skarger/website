module Models exposing (Model, emptyModel, SaveStatus(..))

import Dict exposing (Dict)
import Locations.Models exposing (LocationAreaId, LocationArea)
import Random.Pcg exposing (Seed)


type alias Url =
    String


type SaveStatus
    = NotAttempted
    | Saving
    | Failure
    | Success


type alias Model =
    { url : Url
    , locationAreas : Dict LocationAreaId LocationArea
    , error : String
    , waiting : String
    , locationAreaIndex : Int
    , currentSeed : Seed
    , saveStatus : SaveStatus
    }


emptyModel : String -> Seed -> Model
emptyModel waiting randomSeed =
    { url = ""
    , locationAreas = Dict.empty
    , error = ""
    , waiting = waiting
    , locationAreaIndex = 0
    , currentSeed = randomSeed
    , saveStatus = NotAttempted
    }
