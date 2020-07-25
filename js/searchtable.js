// safari work-around for position:sticky; embed the sticky element inside another div and set its height to the table cell's height
document.querySelectorAll('div.multi').forEach(function(elem) {
	elem.parentElement.style.height = getComputedStyle(elem.parentElement.parentElement).height;
});
