// safari work-around for position:sticky; embed the sticky element inside another div and set its height to the table cell's height
var allMultis = document.querySelectorAll('div.multi');
var rTimer;
window.addEventListener('resize',function(){
	clearTimeout(rTimer);
	// quick resize
	allMultis.forEach(function(e) {
		var h = getComputedStyle(e).height;
		var c = e.parentElement;
		if (parseInt(h,10) > parseInt(c.style.height,10)) {
			c.style.height = h;
		}
	});
	rTimer = setTimeout(resetH, 1300);
});
function resetH() {
	// full resize
	var i = allMultis.length;
	while (i-- > 0) { allMultis[i].parentElement.style.height = 'auto' }
	setH();
}
function setH() {
	allMultis.forEach(function(e) {
		var c = e.parentElement;
		c.style.height = parseInt(getComputedStyle(c.parentElement).height, 10) + 'px';
	});
}
setH();
