# html wrapper stuff

package Roots::Template;
use v5.12;
use CGI qw(cookie);

my @keys = qw(b5 rom py jp stc);
my @sortkeys = qw(book rom py);
my %sortmenu;
@sortmenu{@sortkeys} = ("original (source)", "romanization", "pinyin");
my @disp = cookie('disp');
unless (@disp) {
	@disp = qw( b5 rom ); # just show b5 and romanization by default
}
my %dispcss;
@dispcss{@disp} = (1) x scalar @disp;

sub print_head {
	my ($title, $auth_name, $no_options) = @_;
	$title = ": $title" if $title;
	$Roots::Util::headers_done = 1;
	my $selected = cookie('sort') || 'rom';
	print <<EOF;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
        "http://www.w3.org/TR/1999/REC-html401-19991224/loose.dtd">
<html>
<head>
	<!-- Global site tag (gtag.js) - Google Analytics -->
	<script async src="https://www.googletagmanager.com/gtag/js?id=UA-108355814-1"></script>
	<script>
		window.dataLayer = window.dataLayer || [];
		function gtag(){dataLayer.push(arguments);}
		gtag('js', new Date());

  		gtag('config', 'UA-108355814-1');
	</script>
	<title>Village DB$title</title>
	<meta http-equiv=content-type content="text/html; charset=utf-8">
	<LINK REL="stylesheet" TYPE="text/css" HREF="style.css">
EOF
	unless ($no_options) {
		print <<JSCRIPT;
	<script language="JavaScript" type="text/javascript">
	<!--
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
	//-->
	</script>
	<style type="text/css">
JSCRIPT
		foreach (@keys) {
			print ".$_ {display:" . ($dispcss{$_} ? 'inline' : 'none') . "} ";	
		}
		print "</style>\n";
	}
	print <<EOF;
</head>
<body>
<table border="0" width="100%">
<tr><td width="92"><!-- sidebar -->
<div class="logo">Roots<br>VillageDB</div>
<hr width="80" align="left" size="5">
<a href=display.cgi>Browse</a><p>
<a href=search.cgi>Search</a><p>
<a href=about.html>About</a><p>
</td><td>
EOF

	print <<EOF;
<div style="font-size: smaller" align="right">
<form method="POST" action="sort.cgi" name="sort">
EOF
	if ($auth_name) {
		print "You are logged in as $auth_name. | ",
			  '<a href="login.cgi">my account</a> | ',
			  '<a href="login.cgi?btn=Logout">log out</a>';
		print ' | ' unless $no_options;
	}

	unless ($no_options) {
		print <<EOF;
sort order:
<select name="sort" onchange="document.sort.submit()">
EOF
		foreach (@sortkeys) {
			my $sel = $selected eq $_ ? "selected" : '';
			print qq|<option $sel value="$_">$sortmenu{$_}</option>\n|;
		}
		print <<EOF;
</select>
<noscript>
<input type="submit" value="sort" name="btn"></button>
</noscript>
| <a href="options.cgi"
	onclick="var n = document.getElementById('view').style; n['display'] = n['display'] == 'none' ? 'block' : 'none'; return false">more options</a>
</form>
<form action="options.cgi" method="post" id="view" style="display:none">
EOF
		my %labels;
			@labels{@keys} = qw(big5 romanization pinyin jyutping STC);
		my $count = 4;
		foreach (qw(rom py jp)) {
			print qq#<label><input type="checkbox" onclick="setDisp(this)" value="$count" name="disp" id="$_"#;
			print ' checked' if $dispcss{$_};
			print qq#>$labels{$_}</label>#;
			$count--;
		}
	}
	print "</form></div><hr>\n";
}

sub print_tail {
	print "</td></tr></table>\n";
	print "</body></html>\n";
}
1;
