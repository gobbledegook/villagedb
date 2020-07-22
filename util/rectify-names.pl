#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
use BigName;
binmode(STDOUT, ":utf8");
use utf8;

# force all name fields to match the Pinyin and Jyutping lookup tables
my $DEBUG = $ARGV[0] eq '-t';
my (%jp, %py);
Roots::Util::do_connect();

foreach my $table (qw(Heung Subheung Subheung2 Village)) {
#next unless $table eq 'Village';
	print "doing $table\n";
	my @fields = ('Name');
	push @fields, 'Markets' if $table eq 'Heung';
	push @fields, 'Surnames' if $table eq 'Village';
	
	foreach my $fld (@fields) {
#next unless $fld eq 'Surnames';
		print "...doing $fld\n" unless $fld eq 'Name';
		my $sth = $dbh->prepare("SELECT ID, ${fld}, ${fld}_JP, ${fld}_PY, ${fld}_ROM FROM $table"
			# . " WHERE "
		);
		$sth->execute();
	
		my $total = 0;
		while (my ($id, $u8, $jp, $py, $rom) = $sth->fetchrow_array()) {
			my @u8items = split /, */, $u8;
			my @jpitems = split /, */, $jp;
			my @pyitems = split /, */, $py;
			for my $j (0..$#u8items) {
			# actually this outer loop isn't really necessary since the number of items separated by commas
			# is guaranteed to be equal. In the rom fields there can be mismatches because users might
			# leave out things like "Village" at the end of things.
				my @u8 = split '', $u8items[$j];
				my @jp = split /\s+/, $jpitems[$j];
				my @py = split /\s+/, $pyitems[$j];
				for my $i (0..$#u8) {
					if (!$jp{$u8[$i]} && !$py{$u8[$i]}) {
						($jp{$u8[$i]}, $py{$u8[$i]}) = $dbh->selectrow_array("select Jyutping, Pinyin from Pingyam where Big5='$u8[$i]'");
					}
					my ($db_jp, $db_py) = ($jp{$u8[$i]}, $py{$u8[$i]});
					if ($fld eq 'Surnames') {
						# special case these
						if ($u8[$i] eq '區') {
							$db_jp = 'au1';
							$db_py = 'ou1';
						} elsif ($u8[$i] eq '單') {
							$db_jp = 'sin6';
							$db_py = 'shan4';
						}
					} else {
						if ($u8[$i] eq '區' && $u8[$i+1] =~ /^[道邊村]$/) {
							# this should be keoi1 unless followed by these two chars
							$db_jp = 'au1';
							$db_py = 'ou1';
						} elsif ($u8[$i] eq '校' && $u8[$i+1] eq '椅') {
							$db_jp = 'gaau3';
							$db_py = 'xiao4';
						} elsif ($u8[$i] eq '行' && $i > 0 && $u8[$i-1] eq '中') {
							$db_jp = 'hong4';
							$db_py = 'hang2';
						} elsif ($u8[$i] eq '乾' && $u8[$i+1] eq '田') {
							$db_jp = 'gon1';
							$db_py = 'gan1';
						}
					}
					if ($db_jp ne $jp[$i]) {
						$jp[$i] = $db_jp;
					}
					if ($db_py ne $py[$i]) {
						$py[$i] = $db_py;
					}
				}
				$jpitems[$j] = join ' ', @jp;
				$pyitems[$j] = join ' ', @py;
			}
			my $jpnew = join ', ', @jpitems;
			my $pynew = join ', ', @pyitems;
			if ($jpnew ne $jp || $pynew ne $py) {
				say "$id:$u8 ($rom): replace ";# if (lc($jpnew =~ s/ //gr) ne lc($jp)) && (lc($pynew =~ s/ //gr) ne lc $py);
				if ($jpnew ne $jp) {
					#if (lc($jpnew =~ s/ //gr) ne lc($jp)) {
					say "\t$jp with";
					say "\t$jpnew" ;#}
					$dbh->do("UPDATE $table SET ${fld}_JP = ? WHERE ID=?", undef, $jpnew, $id) // die($dbh->errstr) unless $DEBUG;
				}
				if ($pynew ne $py) {
					$dbh->do("UPDATE $table SET ${fld}_PY = ? WHERE ID=?", undef, $pynew, $id) // die($dbh->errstr) unless $DEBUG;
					#if (lc($pynew =~ s/ //gr) ne lc $py) {
					say "and" if $jpnew ne $jp;
					$py = BigName::format_pinyin($py);
					$pynew = BigName::format_pinyin($pynew);
					say "\t$py with";
					say "\t$pynew" ;#}
				}
				print "\n";# if (lc($jpnew =~ s/ //gr) ne lc($jp)) && (lc($pynew =~ s/ //gr) ne lc $py);
			}
			$total++;
		}
		$sth->finish();
		
		print "...$total done\n";
	}
}
