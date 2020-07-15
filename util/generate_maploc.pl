#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
use Roots::Level::Heung;
binmode(STDOUT, ":utf8");

Roots::Util::do_connect();

my $sth = $dbh->prepare("SELECT Heung.ID, Heung.Name_ROM, Map_Location, latlon, Area.ID FROM Heung JOIN Area ON Heung.Up_ID=Area.ID");
$sth->execute();
while (my ($id, $heung_rom, $maploc, $old_latlon, $area_id) = $sth->fetchrow_array()) {
	next unless $maploc;
	my ($latlon, $county_id, $county, $area, $mgrs) = Roots::Level::Heung::mgrs2latlon($maploc, $area_id);
	if ($latlon) {
		next if $latlon eq $old_latlon;
		say "$county:$area ($id) $heung_rom $mgrs";
		$dbh->do("UPDATE Heung SET latlon=? WHERE ID=?", undef, $latlon, $id)
			// say "Unable to update Heung $id";
	} else {
		say "Heung $id: unable to convert map location $maploc to latitude/longitude."
	}
}
