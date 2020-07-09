#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
binmode(STDOUT, ":utf8");

Roots::Util::do_connect();
$dbh->do("TRUNCATE surnames_index;");
my $sth = $dbh->prepare("SELECT ID, Surnames FROM Village"); # , Surnames_ROM
$sth->execute();

my $total = 0;
while (my ($id, $s, $r) = $sth->fetchrow_array()) {
# 	my @s = split /, */, $s;
# 	my @r = split /, */, $r;
# 	pop @r if $r[-1] =~ /^others$|^various/i;
# 	if (@s != @r) {
# 		say "$id : $s : $r"
# 	}
	foreach (split /,/, $s) {
		$dbh->do("insert into surnames_index (b5, village_id) values ('$_', $id)") // print "error at $id\n";
		$total++;
	}
}

print "...$total entries done\n";
$dbh->disconnect;
