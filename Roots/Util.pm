# utility functions for accessing the database
# and for keeping track of sessions

package Roots::Util 1.32;
use Exporter 'import';

use v5.12;
use utf8;
use Unicode::Normalize;
use Carp;

our ($dbh, %session, $auth_name, $admin, $sortorder, $headers_done,
			@ISA, @EXPORT);
@EXPORT	= qw(bail $dbh $sortorder);

use DBI;
use CGI qw/header cookie/;
use Apache::Session::File;

sub do_connect {
	# your config file should have host, database, user, and password on separate lines
	open(my $config, "<", "Roots/config.txt") or bail("Couldn't find database configuration.");
	my ($host, $db, $user, $pass) = map { chomp; $_ } <$config>;
	close($config);
	$dbh = DBI->connect("DBI:mysql:database=$db;host=$host", $user, $pass,
					{ mysql_enable_utf8mb4 => 1,
					})
		|| bail("Unable to connect to database.");
	return $dbh;
}

# handle errors gracefully
sub bail {
	my ($error) = @_;
	print header(-type=>'text/html; charset=utf-8') unless $headers_done;
	print "<h1>Unexpected Error</h1><p>$error</p>";
	if ($auth_name) {
		print $dbh->errstr, "<p>", $dbh->{Statement}, "<p>";
		print Carp::longmess(); # stack trace
	}
	croak $error;
}

# get_session
# -----------
# see if there's a session_id cookie
# create a session if there isn't one
# tells BigName which keys to display based on the cookie
# returns:
# - the session as a hash ref
# - the cookie itself (which might be undef)
# - name of the user logged in
# for convenience, we save this name in a package variable.
sub get_session {
	my $cookie;
	$headers_done = 0;

	# first the session_id
	my $id = cookie('session_id');

	my $time = localtime;
	{ # this block for the redo
		eval {
			tie %session, 'Apache::Session::File', $id,
				{ Directory=>'/tmp', LockDirectory=>'/tmp' };
		};
		if ($@) {
			# if we can't find the file for the $id, make a new one
			##print STDERR $time . $@;
			$id = undef;
			redo;
		}
	}
	if (!defined($id)) { # remember the session id in a cookie if there isn't one
		$cookie = cookie(-name=>'session_id', -value=>$session{'_session_id'},
							 -expires=>'+1d', -path=>'/');
	}
	
	# now the disp
	my @displayed = cookie('disp');
	@displayed = qw( b5 rom ) unless @displayed;
	@BigName::displayed = @displayed;

	# WARNING don't do this: @BigName::displayed = (cookie('disp') || qw( b5 rom ));
	# because the || operator makes the first operand scalar
	
	# now the sortorder (see sortkeys in Roots::Template)
	# for security, make sure the value is one of rom jp py
	for (cookie('sort')) {
		$sortorder = 'PY', last if /^py$/;
		$sortorder = 'ROM', last if /^rom$/;
		$sortorder = 'book';
	}
	
	$auth_name	= $session{'username'};
	$admin		= $auth_name eq 'dom';
	return \%session, $cookie, $auth_name;
}

# for those times when you don't want to make a new session
sub get_existing_session {
	my $id = cookie('session_id');
	return unless $id;
	eval {
		tie %session, 'Apache::Session::File', $id,
			{ Directory=>'/tmp', LockDirectory=>'/tmp' };
	};
}

sub session_url {
	return $session{page};
}

sub stc2b5 {
	my ($stc) = @_;
	my $b5;
	
	foreach ($stc =~ /\d{4}|,/g) {	# break into 4-digit codes, or commas
		$b5 .= $_ eq ',' ? ',' : $dbh->selectrow_array('SELECT Big5 FROM STC WHERE STC_Code=?', undef, $_);
	}
	return $b5;
}

sub pinyin_tone2num {
	my $s = lc(NFD($_[0])); # decompose
	for ($s) {
		s/u\x{0308}/v/g; # ü to v
		s/\x{0304}(i|o|u|ng(?![aeou])|n(?![aeiouv])|r(?![aeiou]))?/${1}1/g; # match ng before n or else you miss the g
		s/\x{0301}(i|o|u|ng(?![aeou])|n(?![aeiouv])|r(?![aeiou]))?/${1}2/g;
		s/\x{030c}(i|o|u|ng(?![aeou])|n(?![aeiouv])|r(?![aeiou]))?/${1}3/g;
		s/\x{0300}(i|o|u|ng(?![aeou])|n(?![aeiouv])|r(?![aeiou]))?/${1}4/g;
	}

	my @result;
	my $lastpos = 0;
	while ($s =~ /((?:[bpmfdtnlgkhjqxzcsryw]h?)?[iuv]?[aoeiuv](?:i|o|u|ng(?![aeou])|n(?![aeiouv])|r(?![aeiou]))?[12340]?,?)/g) {
		my $syl = $1;
		$lastpos = pos($s);
		push @result, $syl =~ s/(?<![12340,])$/_/r; # insert '_' if no tone number to do toneless search
	}

	if (my $remainder = substr($s, $lastpos)) {
		$remainder =~ /((?:(?:(?:[bpmfdtnlgkhjqxzcsryw]h?)[iuv]?[aoeiuv]?)|[aeo])(?:i|o|u|ng|n|r)?[12340]?)/; # if no vowel for the remainder, require initial consonant
		push @result, $1;
	}
	return join ' ', @result;
}

1;
