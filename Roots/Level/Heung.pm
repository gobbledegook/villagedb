package Roots::Level::Heung;
use v5.12;
use utf8;
use CGI 'param';
use Roots::Util;
use Roots::Template;
our (@ISA);
@ISA = qw(Roots::Level);

sub table { 'Heung' }
sub parent { 'Roots::Level::Area' }
sub _fields	{ return qw/name up_id id markets map_loc latlon/ }

sub display_short {
	my $self = shift;
	$self->SUPER::display_short(@_);
	my ($display) = @_;
	if ($display == 1) {
		my $n = $dbh->selectrow_array('SELECT COUNT(*) FROM Village WHERE Heung_ID=?', undef, $self->{id});
		print " (" . $n . " village" . ($n == 1 ? '' : 's') . ")" if $n;
	}
}

sub display_long {
	my $self = shift;
	$self->SUPER::display_long(@_);
	if ($self->{latlon}) {
		print '[→ approx. location on ' . Roots::Template::gmap_link($self->{latlon}) . 'google maps</a> / '
				. Roots::Template::osm_link($self->{latlon}) . 'openstreetmap</a>]';
	}
}

sub format_full {
	my $self = shift;
	my ($key, $val) = @_;
	my $result = $val;
	if ($key eq 'map_loc' && $self->{'latlon'}) {
		$result .= '<br>[' . Roots::Template::gmap_link($self->{latlon}) . 'approx. location on google maps</a>]<br>['
				. Roots::Template::osm_link($self->{latlon}) . 'approx. location on openstreetmap</a>]';
	}
	return $result;
}

sub _values {
	my $class = shift;
	my ($skip_id) = @_;
	if (scalar param('map_loc')) {
		my ($latlon) = mgrs2latlon(scalar param('map_loc'), $skip_id ? 0 : scalar param('id'));
		param('latlon', $latlon);
	}
	return $class->SUPER::_values($skip_id);
}

sub mgrs2latlon {
	require Geo::Coordinates::UTM;
	my ($maploc, $area_id) = @_;
	$area_id = $dbh->selectrow_array("select Up_ID from Heung where ID=?", undef, scalar param('id')) unless $area_id;
	my ($county_id, $county, $area) = $dbh->selectrow_array('SELECT County.ID, County.Name, Area.Num FROM Area JOIN County ON Area.Up_ID=County.ID WHERE Area.ID=?', undef, $area_id);
	bail("couldn't get county id") unless $county_id;
	my ($letter1, $easting, $northing) = $maploc =~ /(\w)\w ?(\d\d)(\d\d)/;
	my $letter2 = 'E'; # E is the new Q!
	# Per https://www.maptools.com/tutorials/mgrs_usng_diffs:
	# The letter shift also occurs in MGRS when working with other datum
	# that use the Bessel 1841 and Clarke 1880 ellipsoids, which includes
	# much of Africa, Japan, Korea, and Indonesia. When you are working with
	# old maps and MGRS coordinates, be aware that occasional unusual letter
	# adjustments have been used in the past.
	if (defined($northing)) {
		$letter1 = uc $letter1;
		if ($county_id == 2) {
			# for Hoiping, convert from polyconic grid in yards to MGRS in meters
			($easting, $northing) = ($northing, $easting);
			$easting = 92 if $easting == 12; # fix Lung Tong
			$easting = $easting*0.9141 - 8.59;
			$easting = sprintf "%.0f", $easting; # round to integer
			$northing +=100 if $northing < 40;
			$northing = $northing*0.9141 - 23.34;
			$northing = sprintf "%.0f", $northing;
			$letter1 = 'F';
		} elsif ($county_id == 3 || $county_id == 4) {
			# for Sunwui/Chungshan, adjust vertical coordinate
			if ($northing < 30) {
				# they meant GR and not GQ in this case
				$letter2 = 'F'; # F is the new R!
			}
		}
		$easting++; # just to account for a little bit of of the china gps shift
		if ($easting > 99) {
			$letter1 = chr(ord($letter1)+1);
			$easting -= 100;
		}
		$easting = sprintf("%02i", $easting);
		$northing = sprintf("%02i", $northing);

		my $mgrs = "49Q$letter1$letter2$easting$northing";
		my ($lat, $lon) = Geo::Coordinates::UTM::mgrs_to_latlon(6, $mgrs); # 6 is Clarke 1880
		my $latlon = sprintf("%.5f,%.5f", $lat, $lon);
		return $latlon, $county_id, $county, $area, $mgrs;
	} else {
		return '';
	}
}


package Roots::Level::Subheung;
our (@ISA);
@ISA = qw(Roots::Level);
use Roots::Util;

sub table { 'Subheung' }
sub parent { 'Roots::Level::Heung' }

sub display_short {
	my ($self, $link) = @_;
	if ($link) {
		print '<a href="' . $self->myurl() . '">';
	}
	print $self->_short();
	if ($link) {
		print '</a>';
	} else {
		my $table = $self->table();
		my $n = $dbh->selectrow_array("SELECT COUNT(*) FROM Village WHERE ${table}_ID=?", undef, $self->{id});
		print " (" . $n . " village" . ($n == 1 ? '' : 's') . ")" if $n;
	}
}


package Roots::Level::Subheung2;
our (@ISA);
@ISA = qw(Roots::Level::Subheung);

sub table { 'Subheung2' }
sub parent { 'Roots::Level::Subheung' }

1;
