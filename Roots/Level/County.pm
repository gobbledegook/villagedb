package Roots::Level::County;
use v5.12;
our (@ISA);
@ISA = qw(Roots::Level);

sub table { 'County' }
sub parent { return undef }

sub _fields	{ return qw/name id/ }

sub duplicate_check { return 0; }

1;
