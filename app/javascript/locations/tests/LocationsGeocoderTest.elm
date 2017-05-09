module LocationsGeocoderTest exposing (..)

import Dict
import Test exposing (..)
import Expect
import Geocoding exposing (..)
import Random.Pcg exposing (Seed, initialSeed, step)
import Uuid exposing (uuidGenerator)
import Locations.Models exposing (Location)
import Locations.Locations
import Locations.Geocoder as LocationsGeocoder


geocodingSuccessWithAddress : Geocoding.GeocodingResult
geocodingSuccessWithAddress =
    { addressComponents =
        [ { longName = Just "67"
          , shortName = Just "67"
          , types = [ StreetNumber ]
          }
        , { longName = Just "Beacon Street"
          , shortName = Just "Beacon St"
          , types = [ Route ]
          }
        , { longName = Just "Beacon Hill"
          , shortName = Just "Beacon Hill"
          , types = [ Neighborhood, Political ]
          }
        ]
    , formattedAddress = "67 Beacon St, Boston, MA 02108, USA"
    , geometry =
        { location =
            { latitude = 42.3563125
            , longitude = -71.06971639999999
            }
        , locationType = Rooftop
        , viewport =
            { northeast =
                { latitude = 42.3576614802915
                , longitude = -71.0683674197085
                }
            , southwest =
                { latitude = 42.35496351970851
                , longitude = -71.0710653802915
                }
            }
        }
    , types = [ StreetAddress ]
    , placeId = "ChIJIYY7Wp5w44kR3fHLwaS4M2I"
    }


geocodingSuccessWithoutAddress : Geocoding.GeocodingResult
geocodingSuccessWithoutAddress =
    { addressComponents = []
    , formattedAddress = "67 Beacon St, Boston, MA 02108, USA"
    , geometry =
        { location =
            { latitude = 42.3563125
            , longitude = -71.06971639999999
            }
        , locationType = Rooftop
        , viewport =
            { northeast =
                { latitude = 42.3576614802915
                , longitude = -71.0683674197085
                }
            , southwest =
                { latitude = 42.35496351970851
                , longitude = -71.0710653802915
                }
            }
        }
    , types = [ StreetAddress ]
    , placeId = "ChIJIYY7Wp5w44kR3fHLwaS4M2I"
    }


all : Test
all =
    describe "Parsing geocoding response"
        [ test "returns street number and name when present" <|
            \() ->
                Expect.equal
                    "67 Beacon Street"
                    (LocationsGeocoder.nameFromResult geocodingSuccessWithAddress)
        , test "returns the formatted address when street number and name are not present" <|
            \() ->
                Expect.equal "67 Beacon St, Boston, MA 02108, USA"
                    (LocationsGeocoder.nameFromResult geocodingSuccessWithoutAddress)
        ]
