#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
use BigName;
binmode(STDOUT, ":utf8");
use utf8;

my $pass2 = $ARGV[0] eq '-2';

my %list;
while (<main::DATA>) {
	chomp;
	my ($k, $v) = split /:/;
	$list{$k} = $v;
}
my @english = qw/City East Lane Lower Market New Old North Road South Street Town Upper Vil. Vil Village West village 7/;
my %seen;

# find roms for characters where the jyutping differs significantly
# match_onset does a pretty good job
# match_coda only finds a few that match_onset doesn't
# match_vowel gives a lot of false positives, but still found some good errors
Roots::Util::do_connect();

foreach my $table (qw(Heung Subheung Subheung2 Village)) {
	print "doing $table\n";
	my @fields = ('Name');
	push @fields, 'Markets' if $table eq 'Heung';
	push @fields, 'Surnames' if $table eq 'Village';
	
	foreach my $fld (@fields) {
		print "...doing $fld\n" unless $fld eq 'Name';
		my $sth = $dbh->prepare("SELECT ID, ${fld}, ${fld}_ROM, ${fld}_JP FROM $table"
			# . " WHERE "
		);
		$sth->execute();
	
		my $total = 0;
		while (my ($id, $u8, $rom, $jp) = $sth->fetchrow_array()) {
			my @u8items = split /, */, $u8;
			my @romitems = split /, */, $rom;
			my @jpitems = split /, */, $jp;
			for my $j (0..$#u8items) {
				my @u8 = split '', $u8items[$j];
				my @roms = split /[-\s+]/, $romitems[$j];
				my @jp = split /[-\s+]/, $jpitems[$j];
				for my $i (0..$#u8) {
					if (!$pass2 && !match_onset($roms[$i], $jp[$i])) {
						if (grep {$roms[$i] eq $_} @english) {
#							say "$table $id $u8 ($rom) $roms[$i]";
							next;
						}
						if (!$roms[$i]) {
							next;
						}
						$seen{$roms[$i] . ':' . $jp[$i]}++;
					}
					if ($pass2 && match2($roms[$i], $jp[$i])) {
						say "$table $id: $u8 ($rom) $jp[$i]";
					}
				}
			}
			#last if $id == 2;
		}
	}
}

my $n = 0;
for (sort keys %seen) {
	$n++, say "$_:" . $seen{$_} unless $seen{$_} > 20; # ignores the common surnames
}
say $n;

sub match_onset {
	my ($a, $b) = map { lc } @_;
	$a =~ s/^(ts|dz|tz)/z/;
	$a =~ s/^g(?=(in$|ee$))/z/;
	$a = "aau" if $a eq "ow";
	$a =~ s/^ng(?=[ao])//;
	$b =~ s/^ng(?=[ao])//;
	$a = substr($a, 0, 1);
	$b = substr($b, 0, 1);
	$a =~ tr/bdgjc/ptkzz/; # get rid of voicing
	$b =~ tr/bdgjc/ptkyz/; # jp j -> y
	return $a eq $b;
}

sub match_coda {
	my ($a, $b) = map { lc } @_;
	$a = substr($a, -1, 1);
	$b = substr($b, -2, 1); # ignore tone number
	return 1 unless $a =~ /[ptkmng]$/; # ignore vowel endings
	return $a eq $b;
}

my $z = 0;
sub match_vowel {
	my ($a, $b) = map { lc } @_;
my $old = "$a ? $b";
	return 1 if $a eq 'yu' && $b =~ /^jyu/;
	$a =~ s/ze/zi/;
	
	($a) = $a =~ /([aeiou]+.*)/;
	$a = "au" if $a eq "ow";
	$a = "au" if $a eq "ao";
	$a = "iu" if $a eq "ew";
	$a =~ s/u[cptmn](?!g)/a/;

	$a =~ s/ay/ei/;
	$a =~ tr/wy/ui/;
	$a =~ s/oo/u/;

	$a =~ s/r$//; # o$ -> ou, then or$ -> o

	$a =~ s/ue/y/;
	$a =~ s/yu/y/;
	
	$a =~ s/e[ur]/œ/;


	$a =~ s/ee/i/;

	($a) = $a =~ /([aeiouyœ]+)/;

	($b) = $b =~ /([aeiouy]+)/;
	$b =~ s/yu/y/;
	$b =~ s/oe/œ/;
	$b =~ s/eo/u/;
	$b =~ s/aa/a/;
	$b =~ s/ou/o/;
	if ($a ne $b) {
# 	say "$old : $a ? $b";		
# 	die if $z++ == 10;
	}
	return $a eq $b;
}

sub match2 {
	return unless defined $list{$_[0]};
	return $list{$_[0]} eq $_[1];
}

# Village 3963: 獺窯村 (Lai Yiu) caat3
# Village 1447: 黃獍坑 (Wong Kang Hang) ging3
# Village 5168: 下垓里 (Ha Oi Lay) goi1
# Village 5408: 翹桂里 (Yiu Kwai Lay) kiu4
# Village 6074: 駐騄里 (Chu Lui Lay) luk6
# Village 5990: 梁天蓴村 (Leung Tin Chuen Village) seon4
# Heung 277: 潮蓮,豸尾 (Chiu Lin, Tze May) zaai6

# simplified character
# Village 296: 帚管朗 (So Kun Long) zaau2
# Village 4775: 牛擔塘村 (Ngau Tan Tong) daam1

# multiple readings
# Village 2689: 校椅塘 (Kow Yee Tong) haau6
# Village 4864: 中行里 (Chung Hong Lay) hang4

# paste an edited list of results from pass 1 here, then run pass 2

__DATA__
Chuen:seon4:1
Hai:gaai3:8
Hap:caak3:1
Kow:haau6:1
Lai:caat3:1
Oi:goi1:1
Po:fu2:1
So:zaau2:1
Tam:cyun1:2
Tom:cyun1:1
Yiu:kiu4:1
Tan:daam1:1
Hong:hang4:1
Kang:ging3:STC has 獍, text has 猄
Lui:luk6:1
Tze:zaai6:Heung277
Tsan:zyun2:2
