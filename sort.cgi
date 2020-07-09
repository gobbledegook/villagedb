#!/usr/bin/perl
use v5.12;
use lib '.';
use CGI qw(param cookie redirect);
use Roots::Util;

# must get session so we know where to redirect to!
Roots::Util::get_existing_session();

print redirect(-uri=>Roots::Util::session_url(),
				-cookie=>cookie(-name=>'sort',
                             -value=>scalar param('sort'),
                             -expires=>'+1y'));
