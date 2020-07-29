# File: BigName.pm
# by Dominic Yu, 2002.01.20

=head1 NAME

BigName - a package for manipulating complex names for the Roots database

=head1 SYNOPSIS

use BigName;

# initialize a new BigName object
$name = BigName->new($b5, $rom, $py, $jp, $stc);

# get/set values
$foo = $name->b5();
$name->rom("Sai Wu");

# get the name in short/long formats
print $name->format_short();
print $name->format_long();


=head1 DESCRIPTION

each BigName is made up of five simple name variants: b5 (now unicode), rom, py, jp, stc.

format_short takes an optional "comma replacement" parameter. Usually you pass
"aka". In this case, if each simple name consists of two or more comma-separated
items, it will print multiple lines, each line with one of the items.

=cut

package BigName;

use v5.12;
use utf8;
use CGI qw(:html2 :html3 :form param);
our @keys = qw( b5 rom py jp stc );
my %labels;
@labels{@keys} 	= qw( Hant Romanization Pinyin Jyutping STC );

# Constructor

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	return bless { b5=>shift, rom=>shift, 
		py=>shift, jp=>shift, stc=>shift}, $class;
}

# Accessors
for my $datum (@keys) {
   no strict "refs";       # to register new methods in package
   *$datum = sub {
   	   my $self = shift;
	   $self->{$datum} = shift if @_;
	   return $self->{$datum};
   }
}

# a little helper subroutine
sub concat_with_classtags {
	my ($aref, $sep) = @_;
	my ($b5, $rom, $py, $jp) = @$aref; # skip stc
	if ($b5 eq '') {
		$b5 = $rom || ' - ';
		$rom = '';
	}
	$py = format_pinyin($py);
	$jp = format_jyutping($jp);
	my $result;
	my @labels = qw/b5 rom py jp/;
	foreach ($b5, $rom, $py, $jp) {
		my $label = shift @labels;
		next if $_ eq '';
		# assuming b5 is first and always shown
		if ($result) {
			$result .= "<span class=$label>$sep$_</span>";
		} else {
			# always show b5, no <span> needed
			$result = $_;
		}
	}
	return $result;
}

# Object Methods
sub format_short {
	my $self = shift;
	my ($comma_replacement) = @_;
	return concat_with_classtags([@$self{@keys}], ' / ') unless ($comma_replacement);
	
	my @aliases; # array of aliases by key
	my $max_index = 0;
	for my $k (@keys) {
		my $v = $self->{$k};
		next if $k eq 'stc'; # skip stc
		my @items = split /, ?/, $v; # split each item by commas (gives empty array if empty string)
		$max_index = $#items if $#items > $max_index;
		push @aliases, \@items;
	}
	my @result;
	for my $n (0..$max_index) {
		my @values;
		foreach (0..3) {
			# 0..3 means rows for b5 rom py jp; get the nth item for each row
			push @values, $aliases[$_]->[$n];
		}
		push @result, \@values;
	}
	foreach (@result) {
		# now replace each array ref with a string
		$_ = concat_with_classtags($_, ' / ');
	}
	# and finally we join all those strings together
	return join "<br> $comma_replacement ", @result;
}

sub format_long {
	my $self = shift;
	return concat_with_classtags([@$self{@keys}], '<br>');
}


# Package Functions
sub keys {	# optional prefix parameter
	return @keys unless @_;
	
	my ($prefix) = @_;
	return map {$prefix . $_} @keys;
}

sub form_add {
	my ($prefix, $override) = @_;
	my $result = "";
	
	foreach my $key ("rom", "stc") {
		$result .= _editfield($prefix . $key, "", $labels{$key}, $override);
	}
	return $result;
}

sub form_add_confirm {
	my ($prefix) = @_;
	my $result = "";
	
	foreach my $key (@keys) {
		$result .=	param($prefix . $key)
					. _hiddenfield(	$prefix . $key, 
									scalar param($prefix . $key),
									$labels{$key})			# see below
					. "<BR>\n";
	}
	return $result;
}

sub form_edit {
	my $self = shift;
	my ($prefix, $Force_STC_Convert) = @_;
	my $result = "";
	
	foreach my $key (@keys) {
		if ($Force_STC_Convert && $key =~ /^(jp|py)$/) {
			$result .= $self->{$key} . _hiddenfield($prefix . $key, $self->{$key}, $labels{$key}) . "<br>\n";
		} else {
			$result .= _editfield($prefix . $key, $self->{$key}, $labels{$key}, 1);
		}
	}
	return $result;
}

sub form_edit_confirm {
	my ($prefix, $old_name) = @_;
	my $result = "";
	
	foreach my $key (@keys) {
		my $s = $prefix . $key;
		my $changed = param($s) ne $old_name->{$key};
		$result .= q|<SPAN CLASS='changed'>| if $changed;
		$result .=	param($s)
					. hidden(-name=>$s, -default=>scalar param($s))
					. " ($labels{$key})";
		$result .= '*****</SPAN>' if $changed;
		$result .= "<BR>\n";
	}
	return $result;
}

sub _editfield {
	my ($name, $value, $label, $override) = @_;
	return textfield(-name=>$name, -default=>$value, -size=>50,
				-override=>$override) .
		" ($label)<BR>\n";
}

sub _hiddenfield {
	my ($name, $value, $label) = @_;
	return hidden(-name=>$name, -default=>$value) .
		" ($label)";	## do we need to override?
}

# give key, query object
# makes sure the submitted params are OK
# returns an error string, or empty if no problems
sub error_check_params {
	my ($prefix) = @_;
	my $stc = param($prefix . 'stc');
	my $rom = param($prefix . 'rom');
	my @result;
	
	$rom =~ s/\s+/ /g;		# strip extra white space
	$stc =~ s/^\s|\s$//g;	# strip surrounding white space
	$rom =~ s/^\s|\s$//g;
	
	# handle some special cases
	my $surname_exception = ($rom =~ m/[Vv]arious/ || $rom =~ m/, ?[Oo]thers$/)
		if $prefix eq 'surname';
	
	# check for empty
	if ((!$stc or !$rom) && !$surname_exception) {
		push @result, "Some fields were empty ($prefix)!";
	}
	
	# check for equal num of commas
	$rom =~ s/\saka\s/, /g;	# replace aka's with commas (guard against input carelessness)
	$stc =~ s/\saka\s/,/g;
	my $n_items_rom = $rom =~ tr/,//; ## split(/,/, $rom);
	$n_items_rom-- if $surname_exception && $n_items_rom > 0;
	if ($stc =~ tr/,// != $n_items_rom) {
		push @result, "Number of items don't match ($prefix)!";
	}
	
	# check for 4n digits in STC code
	if ($stc !~ m/^(?:\D*\d{4}\D*)*$/ ) {
		push @result, "You seem to be missing some numbers in the STC code ($prefix).";
	}
	
# 	unless (@result) {
# 		push @result, stc_rom_check($stc, $rom);
# 	}
	
	param($prefix . 'rom', $rom);	# save fixed values into query
	param($prefix . 'stc', $stc);
	return @result;
}

sub split_exceptional_roms_inplace {
	for ($_[0]) {
		s/\bToishan\b/Toi shan/;
		s/\bHoiping\b/Hoi ping/;
		s/\bSeto\b/Se to/;
		s/\bShekki\b/Shek ki/;
	}
}

sub stc_rom_check {
	my ($prefix) = @_;
	my $stc = param($prefix . 'stc');
	my $rom = param($prefix . 'rom');
	my @result;
	
	split_exceptional_roms_inplace($rom);
	
	my @stcitems = split /,/, $stc;
	my @romitems = split /,\s?/, $rom;
	ITEM: foreach my $m (0..$#stcitems) {
		my @rom = split /[-\s]+/, $romitems[$m];
		my @stc = $stcitems[$m] =~ /\d{4}/g;
		
		my $one_extra_rom = @stc + 1 == @rom;
		my $one_extra_stc = @stc - 1 == @rom;
		unless ((@stc == @rom)
				|| ($one_extra_stc && $stc[-1] eq "2625" && $rom[-1] !~ /^Vil/)
				|| ($one_extra_stc && $rom[-1] eq "City" && $stc[-1] ne "1004")
					# last word might be "Village" 村 or "City" 城
				|| ($one_extra_rom && (lc($rom[-1]) eq "various" || lc($rom[-1]) eq "others"))
					# allow surnames to be "various" or have "others" at the end of the list
				) {
			push @result, "$romitems[$m] / $stcitems[$m]: number of words/characters don't match!";	
			#next;
		}
		foreach my $n (0..$#stc) {
			next ITEM unless $rom[$n]; # ignore empty rom
			my $char = Roots::Util::stc2b5($stc[$n]); # or else backslash problems happen
			next if $Roots::Util::dbh->selectrow_array(
				"select count(*)from roms where b5=? and rom=?", undef,
				$char, $rom[$n]);
			
			my $error;
			if ($char) {
				my $aref = $Roots::Util::dbh->selectall_arrayref("select rom from roms where b5=?", undef,
					$char);
				$_ = @$_[0] foreach @$aref;	# replace references with strings
				$error = qq|"$rom[$n]" doesn't seem to match STC#$stc[$n] ($char) in the database.|;
				$error .= "<br>Maybe you meant <strong>" . join(' or ', @$aref) . "?</strong>" if (@$aref);
			} else {
				$error = "STC#$stc[$n]: no character found for this number!";
			}
			my $aref = $Roots::Util::dbh->selectall_arrayref(
				"SELECT STC_Code, b5 from roms JOIN STC ON Big5=b5 where rom=?", undef,
				$rom[$n]);
			if (@$aref) {
				$error .= '<br>Perhaps it\'s one of the following:<ul>' if (@$aref);
				foreach (@$aref) {
					$error .= "<li>@$_[0] (@$_[1])</li>";
				}
				$error .= "</ul>";
			}
			push @result, $error;
		}
	}
	return @result;
}

sub stc_rom_check_short {
	my $self = shift;
	my $stc = $self->{'stc'};
	my $rom = $self->{'rom'};
	my @result;
	
	split_exceptional_roms_inplace($rom);
	
	my @stcitems = split /,/, $stc;
	my @romitems = split /,\s?/, $rom;
	ITEM: foreach my $m (0..$#stcitems) {
		my @rom = split /[-\s]+/, $romitems[$m]; # hyphens and/or spaces as separator
		my @stc = $stcitems[$m] =~ /\d{4}/g;
		
		foreach my $n (0..$#stc) {
			next ITEM unless $rom[$n]; # ignore empty rom
			my $char = Roots::Util::stc2b5($stc[$n]);
			next if $Roots::Util::dbh->selectrow_array(
				"select count(*)from roms where b5=? and rom=?", undef,
				$char, $rom[$n]);
			
			my $error;
			push @result, [$stc[$n], $char, $rom[$n]]; # $char might be undefined; that's OK
		}
	}
	return @result;
}


# given key, converts params and adds them to the query object
sub convert_stc {
	my ($prefix) = @_;
	my $stc = param($prefix . 'stc');
	my $rom = param($prefix . 'rom');
	my @stc = ($stc =~ /\d{4}|,/g);	# break into 4-digit codes, or commas
	my (@b5, @py, @jp, $b5, $py, $jp);
	
	my $sth = $Roots::Util::dbh->prepare("SELECT STC.Big5, Pinyin, Jyutping FROM STC LEFT JOIN Pingyam USING (Big5) WHERE STC_Code = ?");
	foreach (@stc) {
		if ($_ eq ",") {
			# if we run into a comma, just push a comma into each array.
			# we'll deal with it later
			push @b5, ','; push @py, ','; push @jp, ',';
			next;
		}
		$sth->execute($_);
		($b5, $py, $jp) = $sth->fetchrow();
		if ($prefix eq 'surname') {
			# special case these
			if ($b5 eq '區') {
				$jp = 'au1';
				$py = 'ou1';
			} elsif ($b5 eq '單') {
				$jp = 'sin6';
				$py = 'shan4';
			}
		}
		push @b5, $b5 || '？';
		push @py, $py || '???';
		push @jp, $jp || '???';
	}
	$sth->finish();
	
	$b5 = join('', @b5);
	$py = join(' ', @py);
	$jp = join(' ', @jp);
	
	#cleanup
	$stc =~ s/[^\d, -]//g;	# strip unwanted chars
	$rom =~ s/\s+/ /;	# strip extra white space
	## also, capitalize, strip surrounding white space
	$py  =~ s/ ,/,/g;	# this is where we fix the comma thing above
	$jp  =~ s/ ,/,/g;
	
	param($prefix . 'b5', $b5);
	param($prefix . 'py', $py);
	param($prefix . 'jp', $jp);
	param($prefix . 'rom', $rom);
	param($prefix . 'stc', $stc);	
}

BEGIN {
my %v2e = ( a=>[qw(a ā á ǎ à)],
			e=>[qw(e ē é ě è)],
			i=>[qw(i ī í ǐ ì)],
			o=>[qw(o ō ó ǒ ò)],
			u=>[qw(u ū ú ǔ ù)],
			v=>[qw(ü ǖ ǘ ǚ ǜ)]
);

sub format_pinyin {
	(my $string = $_[0]) =~
		s{\b([bpmfdtnlgkhjqxzcsryw]h?)?	# initial
			([iuv]?)				# medial
			([aoeiuv])				# vowel
			([iuorn]g?)?			# coda
			([01234])				# tone
		}
		{
			("$1$2" || '’') . "$v2e{$3}[$5]$4" # insert apostrophe if vowel initial
		}gxe;
	# spaceless pinyin
	$string =~ s/(?<!,)\s//g;
	$string =~ s/(^| )’/$1/g; # strip initial apostrophe
	$string =~ s/(^| )(\w)/$1\u$2/g; # capitalize
	return $string;
}

sub format_jyutping {
	my ($s) = @_;
	$s =~ tr/123456/¹²³⁴⁵⁶/;
	return join ', ', map { ucfirst } split /, */, $s;
}
}

1;
