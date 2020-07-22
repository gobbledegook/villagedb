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
my %surnames;
Roots::Util::do_connect();

foreach my $table (qw(Heung Subheung Subheung2 Village)) {
	print "doing $table\n";
	my @fields = ('Name');
	push @fields, 'Markets' if $table eq 'Heung';
	push @fields, 'Surnames' if $table eq 'Village';
	
	foreach my $fld (@fields) {
		print "...doing $fld\n" unless $fld eq 'Name';
		my $sth = $dbh->prepare("SELECT ID, ${fld}, ${fld}_ROM, ${fld}_STC FROM $table"
			# . " WHERE "
		);
		$sth->execute();
	
		my $total = 0;
		while (my ($id, $u8, $rom, $stc) = $sth->fetchrow_array()) {
		    $rom =~ s/^villages formerly under the jurisdiction of //;
			my @u8items = split /, */, $u8;
			my @romitems = split /, */, $rom;
			for my $j (0..$#u8items) {
				my @u8 = split '', $u8items[$j];
				if ($stc) { # skip the new Yanping data
				BigName::split_exceptional_roms_inplace($romitems[$j]);
				my @roms = split /[-\s+]/, $romitems[$j];
				for my $i (0..$#u8) {
					next if $u8[$i] eq ',';
					$seen{$u8[$i]}{"$roms[$i]"}++;
					$seen{$u8[$i]}{"$table:$id"}++ if $table ne 'Village';
				}
				}
				if ($fld eq 'Surnames') {
					my $u = $u8items[$j];
					my $n = $dbh->selectrow_array("select count(*) from surnames where b5='$u'");
					if (!$n && !$surnames{$u}) {
						my $rom = $romitems[$j];
						my ($jp, $py) = $dbh->selectrow_array("select Jyutping, Pinyin from Pingyam where Big5='$u'");
						require BigName;
						my $py2 = ucfirst BigName::format_pinyin($py);
						$surnames{$u} = [$u, $rom, $py2, $py, $jp];
					}
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
		next if $b5 eq '恭'; # in Area, so not found by this script
		print "EXTRA: $b5\t$rom\t";
		print join ',', keys $seen{$b5}->%*;
		print "\n";
	}
}

for (sort {$a->[1] cmp $b->[1]} values %surnames) {
	my ($u, $rom, $py2, $py, $jp) = @$_;
	say "['$u', '$rom', '$py2', '$py'],";
#	$dbh->do("insert into surnames (b5, roms, py, jp) values (?,?,?,?)", undef, $u, $rom, $py, $jp) // die $dbh->errstr();
}

my %known_exceptions = (
	垓=>'Oi',
	城=>'shan',
	朱=>'Che',
	官=>'Kwong',
	碼=>'Pier',
	翹=>'Yiu',
	騄=>'Lui',
	奴=>'Lo',
	橫=>'Wan',
	窟=>'Kwat',
	辰=>'Sen',
	鄉=>'Sub',
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
