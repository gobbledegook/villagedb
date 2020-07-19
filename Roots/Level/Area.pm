package Roots::Level::Area;
use v5.12;
our (@ISA);
@ISA = qw(Roots::Level);

use CGI 'param';

sub table { 'Area' }
sub parent { 'Roots::Level::County' }

sub _fields	{ return qw/num name up_id id/ }

sub head_title {
	my $self = shift;
	return $self->{'num'};
}
sub _short {
	my $self = shift;
	my ($display) = @_;
	if ($display) {
		return $self->{name}->rom() ? $self->{name}->format_short() : $self->{num};
	}
	return $self->{'num'};
}
sub _long {
	my $self = shift;
	return $self->{'num'};
}

sub duplicate_check {
	my $up_id = param('id');
	my $num = param('num');
	my $count = $Roots::Util::dbh->selectrow_array("SELECT COUNT(*) FROM Area WHERE up_id=? AND num=?", undef, $up_id, $num);
	return $count;
}

1;
