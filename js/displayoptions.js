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
window.onkeydown=function(e){if(e.ctrlKey){var i,j;if(e.key=='j'){i=1;j=2}else if(e.key=='p'){i=2;j=1}}if(i){
var s=document.styleSheets[1].cssRules;var n=s.length;var v=s[n-i].style.display;var v2 = v=='inline'?'none':'inline';
s[n-i].style.display=v2;s[n-j].style.display='none';s[n-3].style.display=v;if(document.surname)resetMenu(i==2);}};
