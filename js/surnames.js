function resetMenu(x) {
	var n = document.surname.surname.options; var s;
	var sort_py = document.cookie.indexOf("sort=py") != -1;
	var show_py = x || sort_py || document.cookie.indexOf("&py") != -1;
	for (i=1; i<n.length; i++) {
		if (show_py) {
			if (sort_py) s = m_py[i] + ' (' + m_rom[i] + ')';
			else s = m_rom[i] + ' (' + m_py[i] + ')';
		} else s = m_rom[i];
		n[i].text = s + ' (' + m_b5[i] + ')';
	}
}
