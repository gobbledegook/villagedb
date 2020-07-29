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
var min_lon = 112.9;
var max_lon = 113.0; // coordinates at approximate center of our map area
for (let r of heungs) {
	var radius = Math.trunc(Math.log(r[2])*200)+500;
	var id = r[4] + r[0];
	var lon = r[1][1];
	if (lon < min_lon) { min_lon = lon; }
	else if (lon > max_lon) { max_lon = lon; }
	circles[id] = L.circle(r[1], { color: 'red', weight: 1, fillColor: '#f02', fillOpacity: 0.5, radius: radius })
		.addTo(mymap)
		.bindPopup('<a href="#" onclick="jumpheung(event,\'' + id + '\')">' + r[3] + ' ↓</a><br>' + r[2] + ' village' + (r[2]==1 ? '' : 's'));
}
function jumpheung(e, id) {
	e.preventDefault();
	e.stopPropagation();
	var elem = document.getElementById(id);
	if (!isVisible(elem)) elem.scrollIntoView({block:'center'});
	elem.classList.remove('fade');
	elem.style.backgroundColor = 'yellow';
	setTimeout(function(){elem.classList.add('fade');elem.style.backgroundColor=''}, 500);
}
function isVisible (x) {
	var r = x.getBoundingClientRect();
	return (r.top > 0 && r.left > 0 && r.bottom < (window.innerHeight || document.documentElement.clientHeight) &&
		r.right < (window.innerWidth || document.documentElement.clientWidth));
}
document.addEventListener("DOMContentLoaded", function() {
	var map = document.getElementById('mapid');
	for (let elem of Array.from(document.getElementsByClassName('maplink'))) {
		elem.addEventListener('click', function(e) {
			e.preventDefault();
			e.stopPropagation();
			if (!isVisible(map)) map.scrollIntoView();
			circles[elem.parentElement.id].openPopup();
		}, false);
	}
	mymap.panInsideBounds([[22.3,min_lon],[22.4,max_lon]], {animate:false});
});
