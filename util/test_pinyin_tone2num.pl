#!/usr/bin/perl
use v5.26;
use lib '.';
use Roots::Util;
use open qw(:std :utf8);
use Unicode::Normalize;
use utf8;
use BigName;

# while (<>) {
# 	say Roots::Util::pinyin_tone2num($_);
# 	say '-----';
# }

Roots::Util::do_connect();
my $sth = $dbh->prepare("SELECT Name_PY FROM Village UNION SELECT Surnames_PY FROM Village UNION SELECT Name_PY FROM Heung UNION SELECT Markets_PY FROM Heung UNION SELECT Name_PY FROM Subheung UNION SELECT Name_PY FROM Subheung2 UNION SELECT Name_PY FROM County");
$sth->execute();
my ($i, $x);
while (my $s = $sth->fetchrow_array()) {
	$i++;
	my $t = BigName::format_pinyin($s);	# test round trip conversion: numbers to tone marks,
	my $z = Roots::Util::pinyin_tone2num($t); # then tone marks back to numbers
	next if $z eq $s;
	say "$i: $s -> $t -> $z";
	$x++;
}
if ($x) {
	say "$x failures";
} else {
	say "$i cases passed!"
}
