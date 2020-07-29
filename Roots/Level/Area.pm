package Roots::Level::Area;
use v5.12;
use utf8;
our (@ISA);
@ISA = qw(Roots::Level);

use CGI 'param';
use Roots::Template;

sub table { 'Area' }
sub parent { 'Roots::Level::County' }

sub _fields	{ return qw/num name up_id id latlon/ }

sub head_title {
	my $self = shift;
	if ($self->{num}) {
		return $self->{'num'};
	} else {
		return $self->SUPER::head_title();
	}
}

sub _short {
	my $self = shift;
	my ($display) = @_;
	if ($self->{num}) {
		if ($display) {
			return $self->{name}->format_short() if $self->{name}->rom();
			for ($self->{num}) {
				return '1st Area' if $_ == 1;
				return '2nd Area' if $_ == 2;
				return '3rd Area' if $_ == 3;
				return $_ . 'th Area';
			}
		}
		return $self->{'num'};
	} else {
		return $self->SUPER::_short(@_);
	}
}

sub _long {
	my $self = shift;
	if ($self->{num}) {
		return $self->{'num'};
	} else {
		return $self->SUPER::_long(@_);
	}
}

sub display_long {
	my $self = shift;
	$self->SUPER::display_long(@_);
	if ($self->{latlon}) {
		print '[→ location on ' . Roots::Template::gmap_link($self->{latlon}) . 'google maps</a> / '
				. Roots::Template::osm_link($self->{latlon}) . 'openstreetmap</a>]';
	}
}

sub format_full {
	my $self = shift;
	my ($k, $v) = @_;
	if ($k eq 'latlon') {
		if ($v) {
			return '[' . Roots::Template::gmap_link($v) . 'location on google maps</a>]<br>['
				. Roots::Template::osm_link($v) . 'location on openstreetmap</a>]';
		} else {
			return '-';
		}
	}
	return $self->SUPER::format_full(@_);
}

sub duplicate_check {
	my $up_id = param('id');
	my $num = param('num');
	my $count = $Roots::Util::dbh->selectrow_array("SELECT COUNT(*) FROM Area WHERE up_id=? AND num=?", undef, $up_id, $num);
	return $count;
}

1;
