var mymap = L.map('mapid', {
	center: [22.35551,112.9228],
	zoom: 10,
	scrollWheelZoom: false,
	maxBounds: [[20.41157,110.30273],[24.27200,115.69153]],
	maxBoundsViscosity: 1.0,
});
L.tileLayer('https://tile.thunderforest.com/outdoors/{z}/{x}/{y}.png?apikey={apikey}', {
	maxZoom: 12,
	minZoom: 8,
	apikey: '3ef0de1ebec54804a7ae7dd15780918e',
	attribution: 'Maps &copy; <a href="http://www.thunderforest.com/">Thunderforest</a>, Data &copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors',
}).addTo(mymap);
heungs.forEach(function(r) {
	var radius = Math.trunc(Math.log(r[2])*200)+500;
	var id = r[4] + r[0];
	circles[id] = L.circle(r[1], { color: 'red', weight: 1, fillColor: '#f02', fillOpacity: 0.5, radius: radius })
		.addTo(mymap)
		.bindPopup('<a href="#" onclick="jumpheung(event,\'' + id + '\')">' + r[3] + ' ↓</a>');
});
function jumpheung(e, id) {
	e.preventDefault();
	e.stopPropagation();
	var elem = document.getElementById(id);
	elem.scrollIntoView();
	var origcolor = elem.style.backgroundColor;
	elem.style.backgroundColor = 'yellow';
	var t = setTimeout(function(){elem.style.backgroundColor = origcolor;},(900));
}
document.addEventListener("DOMContentLoaded", function() {
	Array.from(document.getElementsByClassName('maplink')).forEach(function(elem) {
		elem.addEventListener('click', function(e) {
			e.preventDefault();
			e.stopPropagation();
			document.getElementById('mapid').scrollIntoView();
			circles[elem.parentElement.id].openPopup();
		}, false);
	});
});
