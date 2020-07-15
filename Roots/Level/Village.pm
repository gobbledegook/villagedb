package Roots::Level::Village;
use v5.12;
our (@ISA);
@ISA = qw(Roots::Level);

use CGI qw(param);
use Roots::Util;

sub table { 'Village' }

sub _fields	{ return qw/Heung_ID Subheung_ID Subheung2_ID Village_ID id name surname/ }

sub parent {
	my $self = shift;
	my ($level, $id);
	if ($id = $self->{Village_ID}) { $level = 'Village' }
	elsif ($id = $self->{Subheung2_ID}) { $level = 'Subheung2' }
	elsif ($id = $self->{Subheung_ID}) { $level = 'Subheung' }
	else { $id = $self->{Heung_ID}; $level = 'Heung' }
	return "Roots::Level::$level", $id;
}

sub _values {
	my $class = shift;
	my ($skip_id) = @_;
	if (!$skip_id) {
		# when we're adding, we need to set the parent id
		# SUPER::_values will fill it in using param(), so we set it here
		# we only need to set the immediate parent (heung/subheung/subheung2/village_id),
		# and the mysql trigger will take care of the rest
		my $level = param('level');
		my $id = param('id');
		param($level . '_ID', $id);
	}
	return $class->SUPER::_values($skip_id);
}

sub display_short {
	my $self = shift;
	print '<a href="' . $self->myurl() . '">' .$self->_short() . "</a> (" . $self->{'surname'}->format_short() . ")";
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
