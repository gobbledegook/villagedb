#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
use Roots::Template;
use CGI qw(-utf8);

# get the session id
my $q = CGI->new();
Roots::Util::get_existing_session();

# get our displayed keys from the params; otherwise from the previous cookie
my (@displayed, $cookie);
if ($q->param("btn")) {
	@displayed = $q->multi_param('disp');
	$cookie = $q->cookie(-name=>"disp", -value=>\@displayed,
						-expires=>'+1y');
	print $q->redirect(-uri=>Roots::Util::session_url(),
					   -cookie=>$cookie);
	exit;
} else {
	@displayed = $q->cookie('disp');
	@displayed = qw( b5 rom ) unless @displayed;
}

my %checked;
foreach (@displayed) {
	$checked{$_} = 'checked';
}

# print headers
print $q->header();
Roots::Template::print_head("Display Options",undef,1);

# display stuff
print $q->h1("Village DB: Display Options");
print_options();

# finish up
Roots::Template::print_tail();


# subroutines

sub print_options {
	print <<EOF;
<p>Please select the encodings you want displayed:</p>
<form method="POST">
<input type="checkbox" name="disp" id="b5" $checked{b5} value="b5"><label for="b5">Big5</label><br>
<input type="checkbox" name="disp" id="rom" $checked{rom} value="rom"><label for="rom">Romanization</label><br>
<input type="checkbox" name="disp" id="py" $checked{py} value="py"><label for="py">Pinyin (Mandarin)</label><br>
<input type="checkbox" name="disp" id="jp" $checked{jp} value="jp"><label for="jp">Jyutping (Cantonese)</label><br>
<input type="submit" name="btn" value="Submit">
</form>
EOF
}
