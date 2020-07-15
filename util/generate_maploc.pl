#!/usr/bin/perl
use v5.12;
use lib '.';
use Geo::Coordinates::UTM;
use Roots::Util;
binmode(STDOUT, ":utf8");

Roots::Util::do_connect();

my $sth = $dbh->prepare("SELECT Heung.ID, Heung.Name_ROM, Map_Location, latlon, County.ID, County.Name, Area.Num FROM Heung JOIN Area ON Heung.Up_ID=Area.ID JOIN County ON Area.Up_ID=County.ID");
$sth->execute();
while (my ($id, $heung_rom, $maploc, $old_latlon, $county_id, $county, $area) = $sth->fetchrow_array()) {
	next unless $maploc;
	my ($letter1, $easting, $northing) = $maploc =~ /(\w)\w ?(\d\d)(\d\d)/;
	my $letter2 = 'E'; # E is the new Q!
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
		my ($lat, $lon) = mgrs_to_latlon(6, $mgrs); # 6 is Clarke 1880
		my $latlon = sprintf("%.5f,%.5f", $lat, $lon);
		next if $latlon eq $old_latlon;
		# Per https://www.maptools.com/tutorials/mgrs_usng_diffs:
		# The letter shift also occurs in MGRS when working with other datum
		# that use the Bessel 1841 and Clarke 1880 ellipsoids, which includes
		# much of Africa, Japan, Korea, and Indonesia. When you are working with
		# old maps and MGRS coordinates, be aware that occasional unusual letter
		# adjustments have been used in the past.
		say "$county:$area ($id) $heung_rom $mgrs";
		$dbh->do("UPDATE Heung SET latlon=? WHERE ID=?", undef, $latlon, $id)
			// say "Unable to update Heung $id";
	} else {
		say "Heung $id: unable to convert map location $maploc to latitude/longitude."
	}
}
