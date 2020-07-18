#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
use BigName;
binmode(STDOUT, ":utf8");
use utf8;

# find roms in roms table with no supporting name entries
# and vice versa
my (%seen);
Roots::Util::do_connect();

foreach my $table (qw(Heung Subheung Subheung2 Village)) {
	print "doing $table\n";
	my @fields = ('Name');
	push @fields, 'Markets' if $table eq 'Heung';
	push @fields, 'Surnames' if $table eq 'Village';
	
	foreach my $fld (@fields) {
		print "...doing $fld\n" unless $fld eq 'Name';
		my $sth = $dbh->prepare("SELECT ID, ${fld}, ${fld}_ROM FROM $table"
			# . " WHERE "
		);
		$sth->execute();
	
		my $total = 0;
		while (my ($id, $u8, $rom) = $sth->fetchrow_array()) {
		    $rom =~ s/^villages formerly under the jurisdiction of //;
			my @u8items = split /, */, $u8;
			my @romitems = split /, */, $rom;
			for my $j (0..$#u8items) {
				my @u8 = split '', $u8items[$j];
				BigName::split_exceptional_roms_inplace($romitems[$j]);
				my @roms = split /[-\s+]/, $romitems[$j];
				for my $i (0..$#u8) {
					next if $u8[$i] eq ',';
					$seen{$u8[$i]}{"$roms[$i]"}++;
					$seen{$u8[$i]}{"$table:$id"}++ if $table ne 'Village';
				}
			}
			$total++;
		}
		print "...$total done\n";
	}
}

my $sth = $dbh->prepare("SELECT b5, rom FROM roms");
$sth->execute();
while (my ($b5, $rom) = $sth->fetchrow_array()) {
	if (!$seen{$b5}{$rom}) {
		print "EXTRA: $b5\t$rom\t";
		print join ',', keys $seen{$b5}->%*;
		print "\n";
	}
}

my %known_exceptions = (
	垓=>'Oi',
	城=>'shan',
	朱=>'Che',
	官=>'Kwong',
	碼=>'Pier',
	翹=>'Yiu',
	鎮=>'City',
	騄=>'Lui',
);

my $sth = $dbh->prepare("SELECT COUNT(*) FROM roms WHERE b5=? AND rom like ?");
for my $b5 (sort keys %seen) {
	for my $rom (keys $seen{$b5}->%*) {
		next if $rom =~ /^(Heung|Subheung|$)/;
		next if $known_exceptions{$b5} eq $rom;
		$sth->execute($b5, $rom);
		say "missing $b5=>'$rom'," unless $sth->fetchrow_array;
		$sth->finish;
	}
}
