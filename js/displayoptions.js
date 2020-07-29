var dispKeys = ["rom", "py", "jp"];
function dispCookie() {
	var c = document.cookie.split(';').find(s => s.trim().startsWith('disp'));
	return c ? c.split('=')[1].split('&') : ['rom'];
}
function setDispCookie() {
	var v = dispKeys.filter(id => document.getElementById(id).checked).join('&') || 'hant';
	var d = new Date; d.setFullYear(d.getFullYear()+1);
	document.cookie = "disp=" + v + ';expires=' + d.toGMTString() + ';path=/';
}
document.addEventListener("DOMContentLoaded", function() {
	document.getElementById('moreoptions').addEventListener('click', function(e) {
		var n = document.getElementById('view'); n.style.display = getComputedStyle(n).display == 'none' ? 'block' : 'none'; e.preventDefault();
	});
	var r = document.styleSheets[1].cssRules;
	var disp = dispCookie();
	for (let [i, key] of dispKeys.entries()) {
		var b = document.getElementById(key);
		b.checked = disp.includes(key);
		b.addEventListener('click', function(e) {
			var c = e.target;
			c.checked = r[i].style.display === 'none';
			r[i].style.display = c.checked ? 'inline' : 'none';
			setDispCookie();
			if (document.surname) resetMenu();
			if (typeof resetH==="function") resetH();
		});
	}
});
window.addEventListener("keydown",function(e){
	if (e.ctrlKey && (e.key==='j' || e.key==='p')) {
		var show = [];
		var r = document.styleSheets[1].cssRules;
		if (e.key==='j') {
			show[2] = (r[2].style.display==='none' || r[0].style.display==='inline' || r[1].style.display==='inline');
			show[0] = !show[2];
			show[1] = false;
		} else {
			show[1] = (r[1].style.display==='none' || r[0].style.display==='inline' || r[2].style.display==='inline');
			show[0] = !show[1];
			show[2] = false;
		}
		var disp = dispCookie();
		for (let [i, key] of dispKeys.entries()) {
			r[i].style.display = show[i] ? 'inline' : 'none';
			document.getElementById(key).indeterminate = (show[i] !== disp.includes(key));
		}
		if(document.surname){resetMenu(show[1])}
	}
});
