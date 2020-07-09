#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
use Roots::Template;
use CGI qw(-utf8 :standard);
use Email::Valid;

my ($session, $cookie, $authname) = Roots::Util::get_session();
import_names('Q'); # get params
my $btn  = param('btn') || param('def_btn') || ($authname ? 'Edit' : '');
my $self = script_name();

my $dbh = Roots::Util::do_connect();
if ($btn eq "Login") {
	if (pwd_check($Q::username, $Q::pwd)) {
		# if password is correct, redirect back to the page user was at before
		update_login_time();
		print redirect(Roots::Util::session_url());
		$dbh->disconnect;
		exit;
	}
}

# print headers
print header(-type=>'text/html; charset=utf-8', $cookie ? (-cookie=>$cookie) : ());
Roots::Template::print_head("Login",$authname,1);

# display stuff
print h1("Village DB Login");

my %actions = ( Login		=>\&failed_login,
				New_User	=>\&do_new_user,
				Logout		=>\&do_logout,
				Edit		=>\&print_edit,
				Edit2		=>\&save_edit,
				'Forgot Password'		=>\&do_forgot1,
				'Generate New Password' =>\&do_forgot2,
			  );

my $action = $actions{$btn} || \&do_login_screen;
&$action;

# finish up
$dbh->disconnect;
#print "session id: $session->{_session_id}";
Roots::Template::print_tail();


sub do_login_screen {
	print_login();
	print_new_user();
}

sub failed_login {
	print p("The username and/or password was invalid."), "\n";
	print_login();
}

sub update_login_time {
	$dbh->do("UPDATE User SET lastlogin=NOW() WHERE username=?", undef,
			 $Q::username) or bail($DBI::errstr);
	$session->{'username'} = $Q::username;
	timestamp();
}

sub pwd_check {
	my ($uid, $pwd) = @_;
	my ($result) = $dbh->selectrow_array("SELECT pwd=SHA2(?, 224) FROM User WHERE username=?", undef, $pwd, $uid);
	return $result;
}

sub do_new_user {
	$dbh->do("LOCK TABLE User WRITE") || bail("Couldn't lock table: " . $dbh->errstr);
		# we need to lock the table before checking if the information is valid.
		# we check if the username already exists, and then add the username
		# if everything checks out. We can't let anyone sneak in in between.
	if (my $error = invalid_info()) {
		print "Error: $error";
		print_new_user();
	} else {
		$dbh->do("INSERT INTO User (username, pwd, fullname, email, lastlogin) VALUES (?, SHA2(?, 224), ?, ?, NOW())", undef,
				$Q::username, $Q::pwd, $Q::fullname, $Q::email)
			|| bail("Couldn't add user to database: " . $dbh->errstr);
		$session->{'username'} = $Q::username;
		timestamp();
		print "Account created successfully. You are now logged in as $Q::username.";
	}
	$dbh->do("UNLOCK TABLES") || bail("Couldn't unlock table: " . $dbh->errstr);
}

# returns an error string if something's wrong
sub invalid_info {
	# authorization check;
	return "authorization code is invalid" if $Q::auth_code ne 'muggle';
	
	# sanity check
	return "passwords don't match" if $Q::pwd ne $Q::pwd2;
	
	return "username too long" if length $Q::username > 20;
	return "password too long" if length $Q::pwd > 20;
	return "Full Name too long" if length $Q::fullname > 60;
	return "email address too long" if length $Q::email > 60;
	
	return "no username entered" if $Q::username eq "";
	return "no password entered" if $Q::pwd eq "";
	return "no Full Name entered" if $Q::fullname eq "";
	return "no email address entered" if $Q::email eq "";
	
	return "username contains illegal characters" if $Q::username =~ /\W/;
	return "email address is invalid" if !Email::Valid->address($Q::email);
	return "username already exists. Please choose a different username."
		if username_exists();
}

sub save_edit {
	if (my $error = edit_check()) {
		print "Error: $error";
		print_edit();
	} else {
		$dbh->do("UPDATE User SET fullname=?, email=?"
				. ($Q::pwd && ", pwd=SHA2(?, 224)") . " WHERE username=?", undef,
				$Q::fullname, $Q::email, $Q::pwd || (), $authname)
			or bail("Couldn't update database: " . $dbh->errstr);
		print "Your information was updated successfully.";
	}
}

sub edit_check {
	# password check;
	return "password invalid" unless pwd_check($authname, $Q::oldpwd);
	
	# sanity check
	return "passwords don't match" if $Q::pwd ne $Q::pwd2;
	return "password too long" if length $Q::pwd > 20;
	
	return "Full Name too long" if length $Q::fullname > 60;
	return "no Full Name entered" if $Q::fullname eq "";

	return "email address too long" if length $Q::email > 60;
	return "no email address entered" if $Q::email eq "";
	return "email address is invalid" if !Email::Valid->address($Q::email);
}

sub username_exists {
	my ($n) = $dbh->selectrow_array("SELECT COUNT(*) FROM User WHERE username=?", undef, $Q::username);
	return $n;
}

sub do_logout {
	delete $session->{'username'};
	timestamp();
	
	print p("You are now logged out.");
	print p("Back to ", a({-href=>Roots::Util::session_url()}, "the database"), ".");
	print_login();
	print_new_user();
}

sub timestamp() {
	my $x = tied %$session;
	#$x->make_modified;
	$x->save;
}

sub print_login {
	print <<EOF;
<form method="POST" action="$self">
<p>Log in here:</p>

<table>
	<tr>
		<th>username:</th>
		<td><input type="text" name="username" size="20" maxlength="20" value="$Q::username"></td>
	</tr>
	<tr>
		<th>password:</th>
		<td><input type="password" name="pwd" size="20" maxlength="20"></td>
	</tr>
	<tr><td colspan="2" align="center">
		<input type="hidden" name="def_btn" value="Login">
		<input type="submit" name="btn" value="Login" style="width: 12em">
		<input type="submit" name="btn" value="Forgot Password">
	</td></tr>
</table>
</form>
EOF
}

sub print_new_user {
	print <<EOF;
<p>
Create a new account:
</p>
<form method="post" action="$self">
<table>
	<tr>
		<th>username:</th>
		<td><input type="text" name="username" size="20" maxlength="20" value="$Q::username"></td>
	</tr>
	<tr>
		<th>password:</th>
		<td><input type="password" name="pwd" size="20" maxlength="20"></td>
	</tr>
	<tr>
		<th>confirm password:</th>
		<td><input type="password" name="pwd2" size="20" maxlength="20"></td>
	</tr>
	<tr>
		<th>Full Name:</th>
		<td><input type="text" name="fullname" size="40" maxlength="60" value="$Q::fullname"></td>
	</tr>
	<tr>
		<th>Email:</th>
		<td><input type="text" name="email" size="40" maxlength="60" value="$Q::email"></td>
	</tr>
	<tr>
		<th>Authorization Code:</th>
		<td><input type="password" name="auth_code" size="20" maxlength="20"></td>
	</tr>
	<tr><td colspan="2" align="center">
		<input type="hidden" name="btn" value="New_User">
		<input type="submit" value="Create Account">
	</td></tr>
</table>
</form>
EOF
}

sub print_edit {
	my ($fullname,$email) = $dbh->selectrow_array('SELECT fullname, email FROM User WHERE username=?', undef, $authname);
	print <<EOF;
<p>
Edit account information for '$authname':
</p>
<form method="post" action="$self">
<table>
	<tr>
		<th>old password:</th>
		<td><input type="password" name="oldpwd" size="20" maxlength="20"> (required)</td>
	</tr>
	<tr>
		<th>new password:</th>
		<td><input type="password" name="pwd" size="20" maxlength="20"></td>
	</tr>
	<tr>
		<th>confirm password:</th>
		<td><input type="password" name="pwd2" size="20" maxlength="20"></td>
	</tr>
	<tr>
		<th>Full Name:</th>
		<td><input type="text" name="fullname" size="40" maxlength="60" value="$fullname"></td>
	</tr>
	<tr>
		<th>Email:</th>
		<td><input type="text" name="email" size="40" maxlength="60" value="$email"></td>
	</tr>
	<tr><td colspan="2" align="center">
		<input type="hidden" name="btn" value="Edit2">
		<input type="submit" value="Submit">
	</td></tr>
</table>
</form>
EOF
}

sub do_forgot1 {
	if ($Q::username eq '' || !username_exists()) {
		print "Please enter a valid username";
		print_login();
		return;
	}
print <<EOF;
<form method="POST" action="$self">
<table>
	<tr>
		<td>Did you really forget your password?
If so, click below and you'll get a new random password sent to the
email address we have on file for the account named '<b>$Q::username</b>'.
(If your email has changed since you created your account,
this won't work. Contact the database administrator who'll get things sorted
out for you.)
		</td>
	</tr>
	<tr><td align="center">
		<input type="hidden" name="username" value="$Q::username">
		<input type="submit" name="btn" value="Generate New Password">
	</td></tr>
</table>
</form>
EOF
}

sub do_forgot2 {
	my ($email) = $dbh->selectrow_array('SELECT email FROM User WHERE username=?', undef, $Q::username);
	
	unless (Email::Valid->address($email)) {
		print "Error: the email address we have is invalid!!";
		return;	
	}
	
	my $pwd; $pwd .= ('A'..'Z','a'..'z',0..9)[int rand 62] for (0..8);
	my $url = url();
	my $email_text = <<End_of_Mail;
From: Village DB Robot <noreply\@friendsofroots.org>
To: $email
Subject: Village DB account

new password: $pwd

you may wish to change it to something else

log in at $url
End_of_Mail
	
#	print "<pre>$email_text</pre>"; return;
	open (SENDMAIL, "| /usr/sbin/sendmail -t") or bail("couldn't sendmail: $!");
	print SENDMAIL $email_text;
	close SENDMAIL or bail("couldn't sendmail: $! - $?");

	my $rows = $dbh->do("UPDATE User SET pwd=SHA2(?, 224) WHERE username=?", undef,
						$pwd, $Q::username);
	unless ($rows) {
		print "Error setting new password!";
		return;
	}
	
	print p("Random password generated and sent!"), "\n";
}
