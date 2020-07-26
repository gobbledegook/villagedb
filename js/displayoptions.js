function setDisp(c) {
	if (!document.styleSheets) return; var n;
	if (document.styleSheets[1].cssRules) n = document.styleSheets[1].cssRules
	else if (document.styleSheets[1].rules) n = document.styleSheets[1].rules
	else return;
	n[n.length-c.value].style.display = c.checked ? 'inline' : 'none';
	setDispCookie();
	if (document.surname) resetMenu();
}
function setDispCookie() {
	var k = new Array("rom", "py", "jp"); var r = new Array("b5");
	for (var i = 0; i < k.length; i++) {if (document.getElementById(k[i]).checked) r[r.length] = k[i];}
	var d = new Date; d.setFullYear(d.getFullYear()+1);
	document.cookie = "disp=" + r.join('&') + ';expires=' + d.toGMTString() + ';path=/';
}
