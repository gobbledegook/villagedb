# html wrapper stuff

package Roots::Template;
use v5.12;
use CGI qw(cookie url);
use utf8;

my @keys = qw(b5 rom py jp);
my @sortkeys = qw(book rom py);
my %sortmenu;
@sortmenu{@sortkeys} = ("original (source)", "romanization", "pinyin");
my @disp = cookie('disp');
unless (@disp) {
	@disp = qw( b5 rom ); # just show b5 and romanization by default
}
my %dispcss;
@dispcss{@disp} = (1) x scalar @disp;

our ($base);
sub print_head {
	my ($title, $auth_name, $no_options) = @_;
	$title = ": $title" if $title;
	$Roots::Util::headers_done = 1;
	my $selected = cookie('sort') || 'rom';
	my $absolute_url = url( -absolute => 1 );
	my $relative_url = url( -relative => 1 );
	$base = substr($absolute_url, 0, -length($relative_url));
	print <<EOF;
<!DOCTYPE html>
<html>
<head>
	<title>Village DB$title</title>
	<meta charset="utf-8">
	<link rel="stylesheet" type="text/css" href="${base}style.css">
	<script async src="https://www.googletagmanager.com/gtag/js?id=UA-108355814-1"></script>
	<script>window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments)}gtag("js",new Date);gtag("config","UA-108355814-1");</script>
EOF
	unless ($no_options) {
		print qq#<script src="${base}js/displayoptions.js"></script>\n#;
		print qq#<style type="text/css">sup { line-height: 100%; font-size: 67%; } #;
		print ".$_ {display:" . ($dispcss{$_} ? 'inline' : 'none') . "} " foreach @keys;
		print "</style>\n";
	}
	print <<EOF;
	<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.6.0/leaflet.css"
	integrity="sha512-xwE/Az9zrjBIphAcBb3F6JVqxf46+CDLwfLMHloNu6KEQCAWi6HcDUbeOfBIptF7tcCzusKFjFw2yuvEpDL9wQ=="
	crossorigin=""/>
</head>
<body>
<table border="0" width="100%">
<tr><td width="100">
<div class="logo">
<a href="https://www.friendsofroots.org/">Friends of Roots</a>
<hr width="80" align="left" size="5">
VillageDB
</div>
<hr width="80" align="left" size="5">
<a href="${base}display.cgi">Browse</a><p>
<a href="${base}search.cgi">Search</a><p>
<a href="${base}about.html">About</a><p>
</td><td>
EOF

	print <<EOF;
<div style="font-size: smaller" align="right">
<form method="POST" action="${base}sort.cgi" name="sort">
EOF
	if ($auth_name) {
		print "You are logged in as $auth_name. | ",
			  qq#<a href="${base}login.cgi">my account</a> | #,
			  qq#<a href="${base}login.cgi?btn=Logout">log out</a>#;
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
| <a href="${base}options.cgi"
	onclick="var n = document.getElementById('view').style; n['display'] = n['display'] == 'none' ? 'block' : 'none'; return false">more options</a>
</form>
<form action="${base}options.cgi" method="post" id="view" style="display:none">
EOF
		my %labels;
			@labels{@keys} = qw(big5 romanization pīnyīn jyut<sup>6</sup>ping<sup>3</sup>);
		my $count = 3;
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

sub button {
	my ($btn, $level, $id, $url, $extra) = @_;
	my $s = qq#<form method="post" action="$url" style="display:inline;">#;
	$s .= qq#<input type="hidden" name="level" value="$level">#;
	$s .= qq#<input type="hidden" name="id" value="$id">#;
	$s .= qq#<input type="submit" name="btn" value="$btn">#;
	if (ref $extra) {
		while (my ($k, $v) = each %$extra) {
			if ($k =~ /^btn/) {
				$s .= qq#<input type="submit" name="btn" value="$v"># if $v;
			} else {
				$s .= qq#<input type="hidden" name="$k" value="$v">#;
			}
		}
	}
	$s .= "</form>\n";
	return $s;
}

sub gmap_link {
	my ($latlon) = @_;
	return '<a href="https://www.google.com/maps/@?api=1&map_action=map&center=' . $latlon . '&zoom=14" target="_blank">';
}

sub osm_link {
	my ($latlon) = @_;
	return '<a href="https://www.openstreetmap.org/#map=14/' . join('/',split /,/, $latlon) . '" target="_blank">';
}

1;
