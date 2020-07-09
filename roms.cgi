#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
use CGI qw(-utf8 :standard);
binmode(STDOUT, ":utf8");

my ($session, $cookie, $auth_name) = Roots::Util::get_session();
my $dbh = Roots::Util::do_connect();
print header(-type=>'text/html; charset=utf-8', $cookie ? (-cookie=>$cookie) : ());

unless ($Roots::Util::admin) {
	print "Error: must be logged in as admin user to modify romanizations table.";
	exit;
}
print "Something went wrong.", exit if param('btn') ne 'add';

my $statement = "INSERT INTO roms (b5,rom) VALUES (?,?)";
my $b5 = param('b5');
my $rom = param('rom');
$dbh->do($statement, undef, $b5, $rom) or bail("Couldn't add romanization: " . $dbh->errstr . "<br>$statement");
print "Successfully added romanization: $b5, $rom.";

# now uncheck the flag bit
my $level = param('srclev');
bail('Bad table name') unless grep {$_ eq $level} qw/County Area Heung Subheung Subheung2 Village/;

my $id = param('srcid');
my $flag = $dbh->selectrow_array("SELECT Flag FROM $level WHERE ID=?", undef, $id);
$dbh->do("UPDATE $level SET Flag=(Flag & ~4) WHERE ID=?", undef, $id) or bail("Couldn't update $level $id:" . $dbh->errstr);

print "Village id $id's stc_mismatch bit has been unset.";
print "<script>setTimeout(()=>{window.close();},500)</script>";
$dbh->disconnect;
print end_html(), "\n";
