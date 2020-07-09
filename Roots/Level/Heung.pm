package Roots::Level::Generic_Heung;
use v5.12;
use Roots::Util;
our (@ISA);
@ISA = qw(Roots::Level);

sub _heung_level_code;

sub _add_id {
	# do something sneaky to make an entry into Heung_Lookup
	my $self = shift;
	my $code = $self->_heung_level_code;
		
	my $statement = "INSERT INTO Heung_Lookup (Heung_Level) VALUES ($code)";
	$dbh->do($statement)
		|| bail("Couldn't create Heung_Level entry");
	return $dbh->{'mysql_insertid'};
}

sub _locktables {
	my $class = shift;
	my $table = $class->table();
	return "$table WRITE, Heung_Lookup WRITE";
}

sub display_short {
	my $self = shift;
	$self->SUPER::display_short(@_);
	my $n = $dbh->selectrow_array('SELECT COUNT(*) FROM Village WHERE Heung_ID=?', undef, $self->{id});
	print " (" . $n . " villages)" if $n;
}



package Roots::Level::Heung;
our (@ISA);
@ISA = qw(Roots::Level::Generic_Heung);

sub table { 'Heung' }
sub parent { 'Roots::Level::Area' }
sub _heung_level_code { 0 }
sub _fields	{ return qw/name up_id id markets map_loc latlon/ }

sub display_short {
	my $self = shift;
	$self->SUPER::display_short(@_);
	if ($self->{latlon}) {
		print ' [<a href="' . $self->latlon2url($self->{latlon}) . '" target="_blank">map</a>]';
	}
}

sub latlon2url {
	my $self = shift;
	return 'https://www.google.com/maps/@?api=1&map_action=map&center=' . $_[0] . '&zoom=14';
}


package Roots::Level::Subheung;
our (@ISA);
@ISA = qw(Roots::Level::Generic_Heung);

sub table { 'Subheung' }
sub parent { 'Roots::Level::Heung' }
sub _heung_level_code { 1 }
sub display_short { print shift->_short() }


package Roots::Level::Subheung2;
our (@ISA);
@ISA = qw(Roots::Level::Generic_Heung);

sub table { 'Subheung2' }
sub parent { 'Roots::Level::Subheung' }
sub _heung_level_code { 2 }
sub display_short { print shift->_short() }

1;
