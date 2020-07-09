#! /usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
use Encode qw/decode_utf8/;
use utf8;
use open qw(:std :utf8);

Roots::Util::do_connect();
my $sth = $dbh->prepare("SELECT Big5 FROM STC WHERE STC_Code=?");

while (<>) {
	for (/(\d{4}|,\s*|\p{Block: CJK})/g) {
		if (/^,/) {
			print ", ";
		} elsif (/\d/) {
			$sth->execute($_);
			print(($sth->fetchrow_array())[0]);
		} else {
			my ($stc) = $dbh->selectrow_array("SELECT STC_Code FROM STC WHERE Big5=?", undef, $_);
			print $stc;
		}
	}
	print "\n";
}
$sth->finish;
$dbh->disconnect;
