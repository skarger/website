"use strict";

var uuid = require("uuid");

module.exports = (function (uuidGenerator) {
    var publicFunctions = {};
    var map;
    var markers = {};
    const NEW_LOCATION = "NEW_LOCATION";
    const EXISTING_LOCATION = "EXISTING_LOCATION";
    var doubleClickMapHandler = function() {return;}
    publicFunctions.generateUuid = uuidGenerator;

    var defaultZoomLevel = function() {
        return 2;
    }

    var defaultMapCenter = function() {
        var boston = {lat: 42.3601, lng: -71.0589};
        var centerOfTheWorld = {lat: 0, lng: 0};
        return centerOfTheWorld;
    }

    var focusedOpacity = function() {
        return 1.0;
    }
    var unfocusedOpacity = function() {
        return 0.4;
    }

    var toggleBounce = function(marker) {
        if (marker.getAnimation() !== null) {
            marker.setAnimation(null);
          } else {
            marker.setAnimation(google.maps.Animation.BOUNCE);
          }
    }

    publicFunctions.registerDoubleClickMapHandler = function(handler) {
        doubleClickMapHandler = handler;
    };


    publicFunctions.onDoubleClickMap = function(e) {
        var pointOnMap = {
            id: this.generateUuid(),
            latitude: e.latLng.lat(),
            longitude: e.latLng.lng(),
            name: "",
            markerType: NEW_LOCATION,
        };
        var shouldZoomToFit = false;
        this.drawLocationMarker(pointOnMap, shouldZoomToFit);
        doubleClickMapHandler(pointOnMap);
    };

    publicFunctions.initMap = function() {
        map = new google.maps.Map(document.getElementById('map'), {
            zoom: defaultZoomLevel(),
            center: defaultMapCenter()
        });
        map.setOptions({disableDoubleClickZoom: true });
        map.addListener('dblclick', this.onDoubleClickMap.bind(this));
    };

    publicFunctions.drawLocationMarker = function(location, shouldZoomToFit) {
        var position = {
            lat: location.latitude,
            lng: location.longitude,
        };

        var markerOptions = {
            position: position,
            map: map,
            title: location.name,
        };
        if (location.markerType == EXISTING_LOCATION) {
            markerOptions['opacity'] = unfocusedOpacity();
        } else {
            markerOptions['opacity'] = focusedOpacity();
        }

        var marker = new google.maps.Marker(markerOptions);
        markers[location.id] = marker;

        var bounds = new google.maps.LatLngBounds();
        for (var key in markers) {
            bounds.extend(markers[key].getPosition());
        }
        if (shouldZoomToFit) {
            map.fitBounds(bounds);
        }
    }

    publicFunctions.focusMarker = function(locationId) {
        var marker = markers[locationId];
        if (marker) {
            marker.setOpacity(focusedOpacity());
        }
    }

    publicFunctions.unfocusMarker = function(locationId) {
        var marker = markers[locationId];
        if (marker) {
            marker.setOpacity(unfocusedOpacity());
        }
    }

    publicFunctions.updateMarkerTitle = function(markerTitle) {
        var marker = markers[markerTitle.id];
        if (marker) {
            marker.setTitle(markerTitle.name);
        }
    }

    publicFunctions.clearMarkers = function(locationIds) {
        locationIds.forEach(function(locationId) {
            markers[locationId].setMap(null);
            delete markers[locationId];
        });
    };

    return publicFunctions;
})(uuid.v4);
