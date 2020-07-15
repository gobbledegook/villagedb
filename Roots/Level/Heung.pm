package Roots::Level::Heung;
use v5.12;
use Roots::Util;
our (@ISA);
@ISA = qw(Roots::Level);

sub table { 'Heung' }
sub parent { 'Roots::Level::Area' }
sub _fields	{ return qw/name up_id id markets map_loc latlon/ }

sub display_short {
	my $self = shift;
	$self->SUPER::display_short(@_);
	my $n = $dbh->selectrow_array('SELECT COUNT(*) FROM Village WHERE Heung_ID=?', undef, $self->{id});
	print " (" . $n . " villages)" if $n;
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
@ISA = qw(Roots::Level);
use Roots::Util;

sub table { 'Subheung' }
sub parent { 'Roots::Level::Heung' }

sub display_short {
	my ($self, $link) = @_;
	if ($link) {
		print '<a href="' . $self->myurl() . '">';
	}
	print $self->_short();
	if ($link) {
		print '</a>';
	} else {
		my $table = $self->table();
		my $n = $dbh->selectrow_array("SELECT COUNT(*) FROM Village WHERE ${table}_ID=?", undef, $self->{id});
		print " (" . $n . " villages)" if $n;
	}
}


package Roots::Level::Subheung2;
our (@ISA);
@ISA = qw(Roots::Level::Subheung);

sub table { 'Subheung2' }
sub parent { 'Roots::Level::Subheung' }

1;
