module UuidHelpers exposing (generateUuids)

import Uuid exposing (uuidGenerator)
import Random.Pcg exposing (Seed, step)


generateUuids : Seed -> List a -> ( Seed, List String )
generateUuids firstSeed list =
    let
        uuidForItem item ( seed, list ) =
            let
                ( newUuid, newSeed ) =
                    generateUuid seed
            in
                ( newSeed, newUuid :: list )
    in
        List.foldr uuidForItem ( firstSeed, [] ) list


generateUuid : Seed -> ( String, Seed )
generateUuid seed =
    Tuple.mapFirst Uuid.toString (step uuidGenerator seed)
