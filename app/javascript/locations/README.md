# Location Entry Tool

## Overview
The idea is the user has sketched out a route using the Google Directions web app. They can copy the resulting URL from Google:
https://www.google.com/maps/dir/42.3722078,-71.0989845/42.3654429,-71.1037708/42.3607598,-71.096178/@42.3605259,-71.0960819,16.58z/data=!4m2!4m1!3e2

Now the user would like to record the waypoints in their own database. For example this tool might be used by runners who want to track their time to hit various landmarks, or a delivery person recording addresses where they drop off packages. This app allows them to paste in the URL, edit the locations, and save them to the server. They may also double click the map to add locations.

Since the user may have entered locations in the past, pasting a Google Directions URL can result in a duplicate location. This app checks with the backend for existing lat/lngs within 100 meters, and prompts the user to choose if they want to use the existing location or add a new one.


## Technical Details
For the frontend I built this app 90% with Elm, a statically-typed pure functional language that compiles to JavaScript. The other 10% is plain JS to integrate the Google Maps API. Under the hood it involves input rendering, map marker drawing, multiple network requests, and validation prompts in the UI.
1. Top-level app entry point: https://github.com/skarger/website/blob/master/app/javascript/locations/src/index.js
2. Google Maps JS helpers: https://github.com/skarger/website/blob/master/app/javascript/locations/src/locationsMap.js
3. Elm main program: https://github.com/skarger/website/blob/master/app/javascript/locations/src/Main.elm
4. Elm tests: https://github.com/skarger/website/tree/master/app/javascript/locations/tests

The backend is two Rails API endpoints:
1. GET /api/nearby_locations to search for possible duplicates locations
        - Production code: https://github.com/skarger/website/blob/master/app/controllers/api/nearby_locations_controller.rb
        - Tests: https://github.com/skarger/website/blob/master/spec/requests/api/nearby_locations_spec.rb
2. POST /api/location_collections to create the set of new locations
        - Production code: https://github.com/skarger/website/blob/master/app/controllers/api/location_collections_controller.rb
        - Tests: https://github.com/skarger/website/blob/master/spec/requests/api/location_collections_spec.rb

Maybe the most interesting detail on the backend is that the nearby_locations endpoint utilizes PostGIS to perform a geo-query for lat/lngs.
