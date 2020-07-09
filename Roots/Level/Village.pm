package Roots::Level::Village;
use v5.12;
our (@ISA);
@ISA = qw(Roots::Level);

use CGI qw(param);
use Roots::Util;

sub table { 'Village' }

sub _fields	{ return qw/name up_id id surname/ }

sub parent {
	my $self = shift;
	bail("Village object not initialized.") if !defined($self->{'id'});
	
	my ($heung_level) = $dbh->selectrow_array('SELECT Heung_Level FROM Heung_Lookup AS H WHERE H.ID=?', undef, $self->{up_id});
	return 'Roots::Level::' . (qw(Heung Subheung Subheung2))[$heung_level];
}

sub display_short {
	my $self = shift;
	print $self->_short() . "&nbsp; (" . $self->{'surname'}->format_short() . ")";
}

sub _error_check_add {
	my $class = shift;
	my @result;
	my $stc = param('surnamestc');
	return unless $stc;	#ignore empty stc
	
	my $b5 = Roots::Util::stc2b5($stc);
	my $rom = param('surnamerom');
	
	my @s = split /,/, $b5;
	$rom =~ s/\s+//g;		# assuming no spaces in surnames
	my @rom = split /,/, $rom;
	
	foreach (0..$#s) {
		my $rom_search = $dbh->quote($rom[$_]);
		$rom_search =~ s/^'/'%/;
		$rom_search =~ s/'$/%'/;
		my $count = $dbh->selectrow_array("SELECT COUNT(*) FROM surnames WHERE b5=? AND roms LIKE $rom_search", undef, $s[$_]);
		push @result, "surname $s[$_] / $rom[$_] not in database! make sure you typed in and/or spelled the surname(s) correctly."
			if $count == 0;
	}

	return @result;
}

1;
