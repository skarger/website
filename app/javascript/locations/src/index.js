'use strict';


// semantic-ui includes javascript modules too but we are not currently requiring them
require('semantic-ui-css/semantic.min.css')

require("./css/styles.css");
var waiting = require("./img/waiting.gif");
var LocationsMap = require("./locationsMap.js");
import App from './Main'

var setupPorts = function(app) {
    app.ports.draw.subscribe(function(location) {
        var shouldZoomToFit = true;
        LocationsMap.drawLocationMarker(location, shouldZoomToFit);
    });

    app.ports.focus.subscribe(function(locationId) {
        LocationsMap.focusMarker(locationId);
    });

    app.ports.unfocus.subscribe(function(locationId) {
        LocationsMap.unfocusMarker(locationId);
    });

    app.ports.updateTitle.subscribe(function(markerTitle) {
        LocationsMap.updateMarkerTitle(markerTitle);
    });

    app.ports.clear.subscribe(function(locationIds) {
        LocationsMap.clearMarkers(locationIds);
    });

    LocationsMap.registerDoubleClickMapHandler(function(pointOnMap) {
        app.ports.doubleClickMap.send(pointOnMap);
    });
};

var randomInt = function() {
    // we need a random 32 bit int to seed the Elm UUID generator
    // in this case we care much more that the generated UUIDs are unique
    // than whether they are truly unpredictable
    // so we ensure a unique seed with integers for each tenth of a second
    var nowInDeciseconds = Date.now() / 100;
    var maxInt32Bit = 2**32 - 1;
    return Math.floor(nowInDeciseconds % maxInt32Bit);
};


// make available to google maps script tag as callback
window.locationsEntryApp = function() {

    var mountNode = document.getElementById('locations-container');

    var app = App.Main.embed(mountNode, {
        waiting: waiting,
        randomInt: randomInt()
    });
    setupPorts(app);
    LocationsMap.initMap();
}
