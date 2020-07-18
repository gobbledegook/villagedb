#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
binmode(STDOUT, ":utf8");

# normalize capitalization
my $DEBUG = $ARGV[0] eq '-t';
Roots::Util::do_connect();

foreach my $table (qw(Heung Subheung Subheung2 Village)) {
#next unless $table eq 'Village';
	print "doing $table\n";
	my @fields = ('Name');
	push @fields, 'Markets' if $table eq 'Heung';
	push @fields, 'Surnames' if $table eq 'Village';
	
	my $total = 0;
	foreach my $fld (@fields) {
		print "...doing $fld\n" unless $fld eq 'Name';
		my $sth = $dbh->prepare("SELECT ID, ${fld}, ${fld}_ROM FROM $table");
		$sth->execute();
	
		while (my ($id, $u8, $rom) = $sth->fetchrow_array()) {
		    next if $rom =~ /^villages formerly under the jurisdiction of /;
		    next if $rom =~ /Sub-heung/;
		    next if $rom =~ /^There is a market.*/; # just skip these
			my $newrom = $rom =~ s/((\w)(\w*))/exception($1) ? $1 : uc($2).lc($3)/gre;
			$newrom =~ s/, */, /g;
			$newrom =~ s/Others$/others/g;
			if ($newrom ne $rom) {
				say "$id $rom -> $newrom";
				$total++;
				$dbh->do("UPDATE $table SET ${fld}_ROM = ? WHERE ID=?", undef, $newrom, $id) // die($dbh->errstr) unless $DEBUG;
			}
		}
		$sth->finish();
	}
	print "...$total changed\n";
}

sub exception {
	return $_[0] =~ m/^(various|fishermen|others|consisting|of|four|or|five|six|small|floating|population|surnames)$/i;
}
