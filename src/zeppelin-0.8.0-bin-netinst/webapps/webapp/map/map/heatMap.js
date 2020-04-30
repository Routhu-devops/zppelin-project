var map;
var heatLayer;
var heatDataSet;

//function initMap() {
//    console.log('initMap()');
//
//    map = L.map('map').setView([37.8, -96], 2);
//
//    var tiles = L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
//        attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors',
//    }).addTo(map);
//
//    dataToPlot = dataToPlot.map(function (p) { return [p.sw_lat, p.sw_long, p.avgRsrp]; });
//
//    var heat = L.heatLayer(dataToPlot).addTo(map);
//}

function initMap() {
	console.log('initMap()');

	map = L.map('map').setView([37.8, -96], 2);

	var tiles = L.tileLayer('http://{s}.tile.osm.org/{z}/{x}/{y}.png', {
		attribution: '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors',
	}).addTo(map);

	var el = angular.element($('#map').parent('.ng-scope'));
	var $scope = el.scope().compiledScope;

    var angularBindingName = gAngularBinding.bindingName ? gAngularBinding.bindingName : "dataToPlot";
	angular.element(el).ready(function() {
		window.locationWatcher = $scope.$watch(angularBindingName, function(newValue, oldValue) {

            heatDataSet = newValue;
            addHeatLayer(filterData(heatDataSet));
		})
	});

	addPromptListener();
}

function addHeatLayer(dataSet) {
var bindingColumns = gAngularBinding.mapBindings;
			var heatData = dataSet.map(function(plot) {
			    var lat = plot.sw_lat || plot[bindingColumns.lat];
			    var long = plot.sw_long || plot[bindingColumns.long];
			    var intensity = plot.avgRsrp || plot[bindingColumns.intensity];
				return [lat, long, intensity];
			});

            heatLayer = L.heatLayer(heatData);
			heatLayer.addTo(map);
}

function clearMap() {
    map.removeLayer(heatLayer);
}

var gAngularBinding;

function loadMap(angularBinding) {
	gAngularBinding = angularBinding || {};

	loadMapContainer();

	if (window.L) {
	    console.log('window.L found');
	    removeWatch();
	    initMap();
	} else {
	    loadLeafletCss();
	}
}

function removeWatch() {
	if (window.locationWatcher) {
		window.locationWatcher();
	}
}


function loadMapContainer() {
    console.log('Loading map container');
    var sc = document.createElement('div');
    sc.id = 'map'
    sc.style = 'width: 800px; height: 600px;';
    document.getElementsByClassName('resultContained')[0].appendChild(sc);
}

function loadLeafletCss() {
    console.log('Loading leaflet.css');
    var sc = document.createElement('link');
    sc.rel = 'stylesheet';
    sc.href = 'map/leaflet.css';
    sc.onload = loadLeafletJs();
    sc.onerror = function(err) { alert(err); }
    document.getElementsByTagName('head')[0].appendChild(sc);
}

function loadLeafletJs() {
    console.log('Loading leaflet.js');
    var sc = document.createElement('script');
    sc.type = 'text/javascript';
    sc.src = 'map/leaflet.js';
    sc.onload = loadLeafletHeatJs;
    sc.onerror = function(err) { alert(err); }
    document.getElementsByTagName('head')[0].appendChild(sc);
}

function loadLeafletHeatJs() {
    console.log('Loading leaflet-heat.js');
    sc = document.createElement('script');
    sc.type = 'text/javascript';
    sc.src = 'map/leaflet-heat.js';
    sc.onload = initMap;
    sc.onerror = function(err) { alert(err); }
    document.getElementsByTagName('head')[0].appendChild(sc);
}

function addPromptListener() {
	$("#market, #submarket").change(function() {
		//alert($("#market").val() + " " + $("#submarket").val());
		clearMap();
		addHeatLayer(filterData(heatDataSet));
	});
}

function filterData(data) {
	var market = $("#market").val();
	var submarket = $("#submarket").val();
	
	return data.filter(item => (item.market == market || market== "All") && (item.submarket == submarket || submarket == "All"));
}
