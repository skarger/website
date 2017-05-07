'use strict';


// semantic-ui includes javascript modules too but we are not currently requiring them
require('semantic-ui-css/semantic.min.css')

require("./css/styles.css");
var waiting = require("./img/waiting.gif");
var StopsMap = require("./stopsMap.js");
import App from './Main'

var setupPorts = function(app) {
    app.ports.draw.subscribe(function(location) {
        var shouldZoomToFit = true;
        StopsMap.drawStopMarker(location, shouldZoomToFit);
    });

    app.ports.focus.subscribe(function(stopId) {
        StopsMap.focusMarker(stopId);
    });

    app.ports.unfocus.subscribe(function(stopId) {
        StopsMap.unfocusMarker(stopId);
    });

    app.ports.updateTitle.subscribe(function(markerTitle) {
        StopsMap.updateMarkerTitle(markerTitle);
    });

    app.ports.clear.subscribe(function(stopIds) {
        StopsMap.clearMarkers(stopIds);
    });

    StopsMap.registerDoubleClickMapHandler(function(pointOnMap) {
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
window.stopsEntryApp = function() {

    var mountNode = document.getElementById('stops-container');

    var app = App.Main.embed(mountNode, {
        waiting: waiting,
        randomInt: randomInt()
    });
    setupPorts(app);
    StopsMap.initMap();
}
