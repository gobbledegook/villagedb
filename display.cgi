#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Level;
use Roots::Util;
use Roots::Template;
use CGI qw(-utf8 :standard);
binmode(STDOUT, ":utf8");

# initialization
my @levels = qw( County Area Heung Subheung Subheung2 Village );
my $sth;					# statement (query) handle
my %info;					# hash of Level objects
my $self  = url(-absolute => 1);

$Q::level		= param("level");
$Q::id			= param("id");
my $btn			= param("btn") || param('defaultbtn');

# redirect old style params to new style path urls
if (defined($Q::level) && !defined($btn) && Roots::Level->Exists($Q::level) && $Q::id =~ /^\d+$/) {
	my $level = lc($Q::level);
	print redirect(-uri=>"$self/$level/$Q::id", -status=>'301 Moved Permanently');
}
# handle path url
my $url_with_path = url(-absolute=>1, -path=>1);
my $path = substr($url_with_path, length($self));
if (my (undef, $level, $id) = split '/', $path, 3) {
	$level =~ s/^(.)/uc $1/e;
	$Q::level = $level;
	$Q::id = $id;
}

my $add_level	= param("addlevel");
my $past_life	= param("form");
my $searchitem	= param('searchitem');

my $adding	= $btn =~ m/^Add/ || $past_life eq "add";
my $editing	= $btn eq "Edit"  || $past_life eq "edit";

if ((defined($Q::level) && (!Roots::Level->Exists($Q::level) || $Q::id !~ /^\d+$/))) {
	# this error check covers display and edit
	print header(-type=>'text/html', -status=>'400 Bad Request');
	print "Invalid parameters.";
	exit;
}

if ($adding && !Roots::Level->Exists($add_level)) {	# for add
	bail("addlevel not defined: $add_level");
}

# load cookies here
# we have three cookies: session id, display options, and sort order
# (remember, a cookie is just a key/value pair)
# the session (saved in /tmp using Apache::Session) stores
# - user name
# - level, id
# - oldlevel info (only for editing)
# - searchresults (list of id's for admin user to edit search results sequentially)

my ($session, $cookie, $auth_name) = Roots::Util::get_session();
$btn = "Display" if !$auth_name || !$btn; # if you're not logged in, force it to display only

# save this so login.cgi and options.cgi know where to go back to
$session->{'page'} = "$self/" . lc($Q::level) . "/$Q::id";

Roots::Util::do_connect();

if ($editing && ($btn =~ m/^Save/ || $btn =~ m/^Skip/ || $btn =~ m/^Back/ || $btn =~ /^Clear/)) {
	my $module = "Roots::Level::$Q::level";
	$module->save_edit() if $btn =~ m/^Save/;
	my $saved_ids = $session->{searchresults};
	if ($searchitem && $searchitem <= @$saved_ids) {
		# special handling for editing search results in sequence
		if ($btn =~ /^Clear/) {
			my $id = $saved_ids->[$searchitem-1];
			if ($btn =~ /^Clear stc/) {
				$dbh->do("UPDATE $Q::level SET Flag=(Flag & ~4) WHERE ID=?", undef, $id) // bail($dbh->errstr);
			} else {
				$dbh->do("UPDATE $Q::level SET Flag=0, FlagNote='' WHERE ID=?", undef, $id) // bail($dbh->errstr);
			}
			$searchitem++ if $searchitem < @$saved_ids; # clear and move on
		} elsif ($btn =~ m/^Back/) {
			$searchitem--;
		} elsif ($btn =~ /^Skip/) {
			$searchitem++;
		}
		$Q::id = $saved_ids->[$searchitem-1];
		$btn = "Edit";
		param('searchitem', $searchitem);
	} else { #if ($btn =~ m/^Save/) { # special case to redirect
		print redirect("$self/" . lc($Q::level) . "/$Q::id");
		exit;
	}
}

load_info($Q::level, $Q::id);
# %info now loaded
# it includes one Level object for each level of the hierarchy we're viewing
my $title_suffix;
$title_suffix = "$Q::level: " . $info{$Q::level}->head_title()
	if $btn eq "Display" && $Q::level;

# headers
print header(-type=>'text/html; charset=utf-8', $cookie ? (-cookie=>$cookie) : ());
Roots::Template::print_head($title_suffix, $auth_name);

# display stuff

if ($btn eq "Display") {
	if (!defined($Q::level)) { # no parameters passed, display top level
		print h1("Roots Database"), "\n";
		display_children();
	} else {
		# display requested item + children if applicable
		display_hierarchy();
		display_children($Q::level, $Q::id) unless $Q::level eq "Village";
	}

} elsif ($adding) {
	my $module = "Roots::Level::$add_level";
	if ($btn =~ m/^Add / || $btn =~ m/^Oops/) {
		display_hierarchy();
		$module->display_add($Q::id);
	} elsif ($btn eq "Submit") {
		if (my @result = $module->error_check_add()) {
			print h1({class=>'error'},"Error"), p({class=>'error'},\@result), p('Please try again.');
			display_hierarchy();
			$module->display_add($Q::id, 0, 1);
				# offer option to force data entry (ignoring errors)
		} elsif (@result = $module->stc_rom_check()) {
			print h1("Warning"), p({class=>'warn'},\@result),
				p('Please check carefully for typos, e.g., 8 can look like 3. '
				  . 'Sometimes the STC code in the book is wrong. If you find an error, try to type in the correct code (suggestions are listed above when possible), and check the "i found an error" box below.'
				  . ' Otherwise, check the "ignore mismatches" button to skip past this page.');
			$module->display_add($Q::id, 0, 2);
				# offer option to force data entry (ignoring errors)
		} else {
			# to prevent duplicates, we call this function
			# to count the number of similar, duplicate-looking entries.
			# the user then has a chance to insist that it's not actually
			# a duplicate, and a parameter saves the number at that moment.
			# before we INSERT into the db, we check again and compare
			# the two numbers to make sure a duplicate
			# didn't slip by us.
			my $dup_count = $module->duplicate_check();
			$module->display_add_confirm($dup_count);
		}
	} elsif ($btn =~ m/^Save/) {
		display_hierarchy();
		my $x = $module->do_add();
		print "<p>$add_level ";
			$x->display_short;
		print " added to database.</p>";
		$module->display_add($Q::id, 1);	# override with empty defaults
	}

} elsif ($editing) {
	if ($btn eq "Edit" || $btn =~ m/^Oops/) {
		# editing/revising the requested item
		display_hierarchy();
		$session->{'old_info'} = $info{$Q::level};
	} elsif ($btn eq "Submit") {
		# submitting changes (display confirmation screen)
		my $module = "Roots::Level::$Q::level";
		if (my @result = $module->error_check_add()) {
			# reminder: the error check also prettifies the data
			print h1("Warning"), p({class=>'error'},\@result),
				p('These problems probably need to be fixed. You probably want to hit the \'back\' button and try again.');
		}
		$module->display_edit_confirm($session->{'old_info'});
#	} elsif ($btn =~ m/^Save/) {
#		# saving the changes
#		$module->save_edit();
#		load_info($Q::level, $Q::id);	## we need to reload the data, which has changed
#		display_hierarchy();
	}

} elsif ($btn eq "Delete") {
	if (param("del_confirm")) {
		delete_from_db($Q::level, $Q::id); # this changes the values of $Q::level, $Q::id to the parent entity
		Delete_all();	# otherwise wreaks havoc with the default params
		if (!$Q::level) {
			print h1("Roots Database"), "\n";
			display_children();
		} else {
			display_hierarchy();
			display_children($Q::level, $Q::id) unless $Q::level eq "Village";
		}
		my $level = lc $Q::level;
		print qq#<script>window.history.replaceState(null,"","$self/$level/$Q::id")</script>#;
	} else {
		if ($auth_name ne $info{$Q::level}->{created_by}) {
			print "Sorry, in order to delete this record, you must be signed in as the person who created this record."
		} else {
			@BigName::displayed = @BigName::keys;	# show all
			print "<table border=0 cellpadding=5><tr>";
			print th({-class=>"hier"}, $Q::level), '<td class="current">';
			$info{$Q::level}->display_full();
			print "<center>Are you sure you want to delete this item? It'll be gone forever.";
			print start_form("POST", "$self");
			print hidden("level", $Q::level), hidden("id", $Q::id), hidden("del_confirm", 1);
			print submit(-name=>"btn", -value=>"Delete");
			print end_form();
			print '</td></tr></table></center>';
		}
	}
} else {
	print "Nothing happened. Perhaps something went wrong.<br>\n";
}


# finish up
$dbh->disconnect;
Roots::Template::print_tail();
tied(%$session)->save;


sub display_hierarchy {
	print qq|<table border=0 cellpadding=5>\n|;
	foreach my $level (@levels) {
		display_info($info{$level}, $level) if defined($info{$level});
	}
	print "</table>";
}

# load_info($level, $id)
# ---------
# given a level/id, we load the basic information
# (name, romanization, etc.) for it and its parents into the
# global %info hash.

sub load_info {
	my ($table, $id) = @_;
	return unless $table;
	my $package = "Roots::Level::$table";
	while ($package) {	# becomes undef when we're done
		$info{$package->table()} = my $x = $package->new();
		$x->load_from_db($id);
		
		$id = $x->up_id;
		$package = $x->parent();
	}
}

sub delete_from_db {
	my ($level, $id) = @_;

# unless ($Debug) {
	my (undef, $num_c, $num_v) = child($level, $id);
	bail("the $level contains things inside it! delete them first.")
		if $num_c || $num_v;
	$dbh->do("DELETE FROM $level WHERE ID = ?", undef, $id) ||
		bail("delete failed! ". $dbh->errstr);
	if ($level =~ m/heung/i) {
		$dbh->do("DELETE FROM Heung_Lookup WHERE ID = ?", undef, $id) ||
			bail("Heung_Lookup delete failed! ". $dbh->errstr);
	}
# }
	print "$level was deleted successfully.";
	
	# now display the parent
	my $deleted = 0;
	foreach my $level (reverse @levels) {
		if ($deleted && defined($info{$level})) {
			$Q::level = $level;
			$Q::id = $info{$level}->{id};
			last;
		}
		if (defined($info{$level})) {
			delete $info{$level};
			$deleted = 1;
		}
	}
	$Q::level = '' if $level eq "County";
}

# display_info($info, $level)
# ------------
# given hash reference and level, prints the info
sub display_info {
	my ($info, $level) = @_;
	my $level_current = $level eq $Q::level;
	
	print "<tr>";
	print th({-class=>"hier"}, $level), "\n";
	
	if ($level_current and not $adding ) { #$btn eq "Display" || $editing
		print '<td class="current">';
		if ($btn eq "Edit" ||  $btn =~ /^Oops/) { #$editing &&
 			$info->display_edit();
 			print '</td>';
		} else {	# Display, or after saving from Edit
			print "$level has been updated." if ($btn =~ /^Save/); #$editing && 
			$info->display_full();
			if ($auth_name) {
				print qq|</td><td class="current">|;
				print start_form("POST", "$self");
				print hidden("level", $level), hidden("id", $info->{"id"});
				print submit(-name=>"btn", -value=>"Edit");
				my (undef, $num_c, $num_v) = child($level, $info->{"id"});
				if ($num_c == 0 && $num_v == 0
					&& ($auth_name eq $info{$Q::level}->{created_by} || $Roots::Util::admin)) {
					# only show Delete button if there are no children, and the same user created that record
					print br(),submit(-name=>"btn", -value=>"Delete")
				}
				print end_form();
			}
		}
	} else {
		print "<td>";
		$info->display_long();
	}
	
	print "</td></tr>\n";
}

## note: displaying counties is just a special case of display_children
sub display_children {
	my ($level, $id) = @_;
	
	my ($child, $num_children, $num_villages) = child($level, $id);
	if ($level eq "Heung") {
		# show all Villages, grouped by Heung, Subheung, etc.
		my $subheungs = print_subheungs($num_children, $id) if $auth_name || $num_children;
		print_villages($num_villages, $id, $subheungs) if $auth_name || $num_villages;
	} elsif ($auth_name || $num_children) {
		print_list($child, $id, $num_children);
	}
}

sub print_subheungs {
	my ($num_subheungs, $heung_id) = @_;
	my $end_par = ":</p>\n";
	my $output = "<p>Contains $num_subheungs subheung" . ($num_subheungs == 1 ? '' : 's') . $end_par;
	if ($auth_name) {
		$output .= start_form("POST", "$self");
		$output .= qq#<input type="hidden" name="level" value="$Q::level">#;
		$output .= '<input type="hidden" name="addlevel" value="Subheung">';
		$output .= qq#<input type="hidden" name="id" value="$heung_id">#;
		$output .= submit(-name=>"btn", -value=>"Add Subheung");
		$output .= end_form(), "\n";
	}
	print $output, return if $num_subheungs == 0;
	
	my $num_subsubheungs;
	my $sql = 'SELECT ' . join(',', map {"Subheung.$_"} Roots::Level::Subheung->query_fields()) . ', GROUP_CONCAT(DISTINCT Subheung2.ID ORDER BY 1), COUNT(DISTINCT Village.ID)'
		. ' FROM Subheung LEFT JOIN Subheung2 ON Subheung2.Up_ID=Subheung.ID LEFT JOIN Village ON Village.Up_ID=Subheung.ID'
		. " WHERE Subheung.Up_ID=? GROUP BY Subheung.ID ORDER BY Subheung.ID";
	$sth = $dbh->prepare($sql);
	$sth->execute($heung_id) or bail("Error reading from database.");
	$output .= "<ol>";
	my %subheungs_hash;
	my @row;
	while (@row = $sth->fetchrow_array()) {
		$output .= "<li>";
		my $x = Roots::Level::Subheung->new();
		$x->load(@row);
		$subheungs_hash{$x->{id}} = $x;
		my $subsubheungs = $row[-2];
		my $num_villages = $row[-1];
		$output .= '<a href="#h' . $x->{id} . '">' unless $num_villages == 0;
		$output .= $x->_short();
		$output .= '</a>' unless $num_villages == 0;
		if ($auth_name) {
			$output .= '<form method="post" action="' . $self . '" style="display:inline">';
			$output .= '<input type="hidden" name="level" value="Subheung">';
			$output .= '<input type="hidden" name="id" value="' . $x->{id} . '">';
			$output .= '<input type="submit" name="btn" value="Edit">';
			if ($num_villages == 0) {
				$output .= '<input type="hidden" name="addlevel" value="Village">';
				$output .= '<input type="submit" name="btn" value="Add Village to Subheung">';
			}
			if (!defined($subsubheungs) && $num_villages == 0 && ($auth_name eq $x->{created_by})) {
				$output .= '<input type="submit" name="btn" value="Delete">';
			}
			$output .= '</form>';
		}
		$output .= "</li>\n";
		if (defined($subsubheungs)) {
			$output .= "<ol>";
			for my $subheung2_id (split /,/, $subsubheungs) {
				$num_subsubheungs++;
				$output .= '<li style="list-style-type: lower-alpha;">';
				my $y = Roots::Level::Subheung2->new();
				$y->load_from_db($subheung2_id);
				$subheungs_hash{$y->{id}} = $y;
				$output .= $y->_short();
				if ($auth_name) {
					$output .= '<form method="post" action="' . $self . '" style="display:inline">';
					$output .= '<input type="hidden" name="level" value="Subheung2">';
					$output .= '<input type="hidden" name="id" value="' . $y->{id} . '">';
					$output .= '<input type="submit" name="btn" value="Edit">';
					my (undef, $num_villages) = child('Subheung2', $y->{id});
					if ($num_villages == 0) {
						$output .= '<input type="hidden" name="addlevel" value="Village">';
						$output .= '<input type="submit" name="btn" value="Add Village to Sub-subheung">';
						$output .= '<input type="submit" name="btn" value="Delete">' if ($auth_name eq $y->{created_by});
					}
					$output .= '</form>';
				}
				$output .= "</li>\n";
			}
			$output .= "</ol>\n";
		}
	}
	$output .= "</ol>";
	if ($num_subsubheungs) {
		$output =~ s/$end_par/" and $num_subsubheungs minor subheung" . ($num_subsubheungs == 1 ? '' : 's') . $end_par/e;
	}
	print $output;
	return \%subheungs_hash;
}

sub print_villages {
	my ($num_villages, $heung_id, $subheungs) = @_;
	print "<p>Contains $num_villages village" . ($num_villages == 1 ? '' : 's')
		. (scalar(keys %$subheungs) ? ' in total' : '')
		. ":</p>\n";
	if ($auth_name) {
		print start_form("POST", "$self");
		print qq#<input type="hidden" name="level" value="$Q::level">#;
		print '<input type="hidden" name="addlevel" value="Village">';
		print qq#<input type="hidden" name="id" value="$heung_id">#;
		print submit(-name=>"btn", -value=>"Add Village to Heung");
		print end_form(), "\n";
	}
	return if $num_villages == 0;
	my $sql = 'SELECT ' . join(',', Roots::Level::Village->query_fields()) . ', Subheung_ID, Subheung2_ID FROM Village'
		. " WHERE Heung_ID=? ORDER BY Subheung_ID, Subheung2_ID";
	if ($sortorder =~ m/^(PY|ROM)$/ ) {
		$sql .= ", Name_$sortorder";
	}
	$sth = $dbh->prepare($sql);
	$sth->execute($heung_id) or bail("Error reading from database.");
	my @row;
	my $x = Roots::Level::Village->new();
	my $last_subheung_id = undef;
	my $last_subheung2_id;
	while (@row = $sth->fetchrow_array()) {
		$x->load(@row);
		my $subheung_id = $row[-2];
		my $subheung2_id = $row[-1];
		if (!defined($last_subheung_id) || ($subheung_id != $last_subheung_id)) {
			print "</ol>\n" if $last_subheung2_id != 0 && defined($last_subheung_id);
			$last_subheung2_id = 0;
			print "</ol>\n" if defined($last_subheung_id);
			$last_subheung_id = $subheung_id || 0;
			if ($subheung_id != 0) {
				print qq|<div id="h$subheung_id" class="band-subheung">| . $subheungs->{$subheung_id}->_short();
				if ($auth_name) {
					print '<form method="post" action="' . $self . '" style="display:inline">';
					print '<input type="hidden" name="level" value="Subheung">';
					print '<input type="hidden" name="addlevel" value="Village">';
					print '<input type="hidden" name="id" value="' . $subheung_id . '">';
					print submit(-name=>"btn", -value=>"Add Village to Subheung");
					print '</form>';
# 					print '<form method="post" action="' . $self . '" style="display:inline">';
# 					print '<input type="hidden" name="level" value="Subheung">';
# 					print '<input type="hidden" name="addlevel" value="Subheung2">';
# 					print '<input type="hidden" name="id" value="' . $subheung_id . '">';
# 					print submit(-name=>"btn", -value=>"Add Sub-subheung");
# 					print '</form>';
				}
				print "</div>\n";
			}
			print "<ol>";
		}
		if (defined($subheung2_id) && $subheung2_id != $last_subheung2_id) {
			print "</ol>\n" if $last_subheung2_id != 0;
			print '<li style="list-style-type: lower-alpha;"' . ($last_subheung2_id == 0 ? ' value="1"' : '') . '>';
			$last_subheung2_id = $subheung2_id;
			print $subheungs->{$subheung2_id}->_short();
			if ($auth_name) {
				print '<form method="post" action="' . $self . '" style="display:inline">';
				print '<input type="hidden" name="level" value="Subheung2">';
				print '<input type="hidden" name="addlevel" value="Village">';
				print '<input type="hidden" name="id" value="' . $subheung2_id . '">';
				print submit(-name=>"btn", -value=>"Add Village to Sub-subheung");
				print '</form>';
			}
			print "</li>";
			print "<ol>";
		}
		print "<li>";
		$x->display_short();
		if ($auth_name) {
			print '<form method="post" action="' . $self . '" style="display:inline">';
			print '<input type="hidden" name="level" value="Village">';
			print '<input type="hidden" name="id" value="' . $x->{id} . '">';
			print '<input type="submit" name="btn" value="Edit">';
			print '</form>';
		}
		print "</li>\n";
	}
	print "</ol>\n" if $last_subheung2_id != 0;
	print "</ol>";
}

sub print_list {
	my ($level, $id, $num) = @_;
	if ($auth_name) {
		print start_form("POST", "$self");
		print qq#<input type="hidden" name="level" value="$Q::level">#;
		print hidden(-name=>"addlevel", -default=>[$level]);
		print qq#<input type="hidden" name="id" value="$id">#;
		print submit(-name=>"btn", -value=>"Add $level");
		print end_form(), "\n";
	}
	return if $num == 0;

	print "<p>Contains $num " . ($num == 1 ? $level : plural($level)) . ":</p>\n";
	my $module = "Roots::Level::$level";
	my $sql = 'SELECT ' . join(',', $module->query_fields()) . ' FROM ' . $level;
	if ($id) {
		$sql .= ' WHERE Up_ID=?';
	}
	if ($level ne "Area" && $sortorder =~ m/^(PY|ROM)$/ ) {
		$sql .= " ORDER BY Name_$sortorder";
	}
	$sth = $dbh->prepare($sql);
	$sth->execute($id || ()) or bail("Error reading from database.");
	print "<ol>";
	my @row;
	my $x = $module->new();	# recycle this reference
	while (@row = $sth->fetchrow_array()) {
		print "<li>";
		$x->load(@row);
		$x->display_short(); print "</li>\n";
	}
	print "</ol>";
}

sub plural {
	my ($x) = @_;
	return "Counties" if $x eq "County";
	return $x . "s";
}

BEGIN {	# a protected, early-execution block
# we cache the values so we don't have to make so many sql calls.
my %stored;
my %children = qw(County    Area
				  Area      Heung
				  Heung     Subheung
				  Subheung  Subheung2
				  Subheung2 Village );

# returns name of table at the next level of the hierarchy,
# along with the count.
# The third returned argument is the number of villages, for Heungs and Subheungs.
sub child {
	my ($level, $id) = @_;
	return if $level eq 'Village';
	return @{$stored{$level, $id}} if $stored{$level, $id};	# using multi-dimensional array emulation
	
	my $child = $children{$level} || "County";
	my $sql = 'SELECT COUNT(*) FROM ' . $child;
	if ($id) {
		$sql .= ' WHERE Up_ID=?';
	}
	my $num = $dbh->selectrow_array($sql, undef, $id || ());

	$stored{$level, $id} = [$child, $num];
	return $child, $num unless $level =~ m/heung$/i;

	my $column = $level . '_ID';
	my $num_villages = $dbh->selectrow_array("SELECT COUNT(*) FROM Village WHERE $column=?", undef, $id);
	push @{$stored{$level, $id}}, $num_villages;
	return $child, $num, $num_villages;
}
}
