#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
use Roots::Template;
use Roots::Level;
use utf8;
binmode(STDOUT, ":utf8");
use CGI qw(-utf8 :standard);
use Roots::Surnames;

# get params, cookies
my ($session, $cookie, $auth_name) = Roots::Util::get_session();
my $q = CGI->new();
my $reloaded;
if ($q->param('reload')) {
	$q = $session->{query};
	$reloaded = 1;
}

$q->import_names('Q');
my $self = $q->url(-absolute=>1);
my $btn = $q->param('btn');
my $surname; # assigned in print_search()

# save this so login.cgi and options.cgi know where to go back to
$session->{'page'}	= $self . '?reload=1';
$session->{'query'} = $q;


my $dbh = Roots::Util::do_connect();

print header(-type=>'text/html; charset=utf-8', $cookie ? (-cookie=>$cookie) : ());
Roots::Template::print_head('Search', $auth_name);

my %actions = ( SearchSurname=>\&do_search_by_surname,
				SearchOther=>\&do_search_other,
				SearchAdvanced=>\&do_search_superuser,
				 );

my $action = $actions{$btn} || \&do_search_screen;
&$action;

$dbh->disconnect;
print qq|<script src="${Roots::Template::base}js/searchtable.js"></script>\n| if $btn;
print hr, qq|\n<div class="footer">|;
print "VillageDB $Roots::Util::VERSION by Dominic Yu.\n";
print "</div>";
print qq#<script>window.history.replaceState(null,"","$self")</script># if $reloaded;
Roots::Template::print_tail();
tied(%$session)->save;


#subroutines

sub do_search_screen {
	print_search();
}

sub do_search_by_surname {
	print_search(); # this will also sort the surnames array and assign $surname
	return unless $surname;
	print "<hr>";
	
	# experimental map
	my $sth = $dbh->prepare("select Heung.ID, latlon, count(Village.ID), Heung.Name from Heung join Village on Village.Heung_ID=Heung.ID join surnames_index on surnames_index.village_id=Village.ID where b5=? and Heung.latlon != '' group by Heung.ID") // bail();
	$sth->execute($surname) // bail();
	my $heunginfo = '';
	while (my ($id, $latlon, $n, $name) = $sth->fetchrow_array()) {
		$heunginfo .= "[$id,[$latlon],$n,'$name','h'],";
	}
	my $sth = $dbh->prepare("select Area.ID, Area.latlon, count(Village.ID), Area.Name from Area join Heung on Heung.Up_ID=Area.ID join Village on Village.Heung_ID=Heung.ID join surnames_index on surnames_index.village_id=Village.ID where b5=? and Area.latlon is not null group by Area.ID") // bail();
	$sth->execute($surname) // bail();
	while (my ($id, $latlon, $n, $name) = $sth->fetchrow_array()) {
		$heunginfo .= "[$id,[$latlon],$n,'$name','t'],";
	}
	if ($heunginfo) {
		print '<script src="https://cdnjs.cloudflare.com/ajax/libs/leaflet/1.6.0/leaflet.js" integrity="sha512-gZwIG9x3wUXg2hdXF6+rVkLF/0Vi9U8D2Ntg4Ga5I5BZpVkVxlJWbSQtXPSiUTtC0TjtGOmxa1AJPuV0CPthew==" crossorigin=""></script>';
		print '<div id="mapid"></div>';
		print "<p>Heungs/townships containing villages with surname $surname (larger circles means more villages with this surname).</p>\n";
		print "<script>";
		print 'var circles = {}; var heungs = [';
		print $heunginfo;
		print "];</script>\n";
		print qq|<script src="${Roots::Template::base}js/searchmap_load.js"></script>\n|;
	}

	# searching via the index is faster, but you have to keep the surnames_index table updated all the time!
	print_results("surnames_index.b5='$surname'", 'Village');

	# slow, non-indexed alternative
	#print_results("Surnames LIKE '%$surname%'");

	printf '<p>Query took %.3f seconds.</p>', $Roots::Level::ELAPSED;
}

sub do_search_other {
	print_search();
	return unless $Q::text;
	print "<hr>";
	
	if ($Q::text =~ /^\\/) {
		# secret searches
		for ($Q::text) {
			print_results(1, 'Heung'), last if /^\\heu/i;
			print_results(1, 'Subheung2'), last if /^\\subh.*?2/i;
			print_results(1, 'Subheung'), last if /^\\subh/i;
			print_results("Village.Flag=0 and Village.FlagNote!=''", 'Village'), last if /^\\note/i;
		}
		printf '<p>Query took %.3f seconds.</p>', $Roots::Level::ELAPSED if $Roots::Level::ELAPSED;
		return;
	}
	
	my $display_text;
	my $col = "Name";
	
	# automatically figure out Chinese vs romanization search
	if ($Q::field ne 'py') {
		if ($Q::text =~ /^\p{Block: CJK}/) {
			$Q::field = 'b5';
		} elsif ($Q::field eq 'b5' && $Q::text =~ /^[[:ascii:]]+$/) {
			$Q::field = 'rom';
		}
	}
	
	# the ROM and PY fields are ascii only internally, so check these inputs
	# otherwise mysql will throw an "illegal mix of collations" error
	if ($Q::field eq 'rom') {
		$col .= '_ROM';
		unless ($Q::text =~ /^[[:ascii:]]+$/) {
			print "No results found.<p>You searched for $Q::text, which doesn't look like romanization.";
			return;
		}
	} elsif ($Q::field eq 'py') {
		$col .= '_PY';
		my $pinyin = Roots::Util::pinyin_tone2num($Q::text); # extract usable pinyin from the input string
		unless ($pinyin) {
			print "No results found.<p>You searched for $Q::text, which doesn't look like pinyin. You can search for pinyin using numbers for tones, e.g., tai2 for tái.";
			return;
		}
		$Q::text = $pinyin;
		$display_text = $pinyin =~ s/_//gr;
	}
	$display_text ||= $Q::text;
	
	my $text = $dbh->quote($Q::text);
	for ($Q::how) {
		$text =~ s/^'/'%/	if /z/;
		$text =~ s/'$/%'/	if /a/;
	}
	
	my %h2e = (a=>'begins with', az=>'contains');
	print "<p>Searching for " . ($Q::searchheungs ? 'heungs, admin. districts, and ' : '') . "villages whose name"
		. ($Q::field eq 'py' ? ' in pinyin' : '') ." $h2e{$Q::how} “$display_text”.</p>";
	
	my $foundheungs;
	if ($Q::searchheungs) {
		print_results("Heung.$col LIKE $text", 'Heung') and $foundheungs = 1;
		print_results("Subheung.$col LIKE $text", 'Subheung') and $foundheungs = 1;
		print_results("Subheung2.$col LIKE $text", 'Subheung2') and $foundheungs = 1;
	}
	print_results("Village.$col LIKE $text", 'Village', $foundheungs);
	printf '<p>Query took %.3f seconds.</p>', $Roots::Level::ELAPSED;
}

sub do_search_superuser {
	print_search();
	print "<hr>";
	return unless $Q::z;
	
	print_results("$Q::z", $Q::table);
	printf '<p>Query took %.3f seconds.</p>', $Roots::Level::ELAPSED;
# 	} else {
# 		my $x = Roots::Level->new($Q::table);
# 		my $fields = join(',', $x->query_fields(), qw(Date_Modified Created_By Flag FlagNote));
# 		my $sth = $dbh->prepare("SELECT $fields FROM $Q::table WHERE $Q::z");
# 		$sth->execute() or bail("Error reading from database.");
# 		my @saved_ids;
# 		my $n = 1;
# 		print q|<table class="search">|;
# 		while (my @ary = $sth->fetchrow_array()) {
# 			print "<tr><td>$n</td><td>";
# 			$x->load(@ary);
# 			$x->display_short();
# 			print "</td><td>";
# 			print Roots::Template::button('Edit', $Q::table, $x->{id}, 'display.cgi', {searchitem=>$n});
# 			print "[$x->[-1]{flag}] $x->[-1]{flagnote}" if $x->[-1]{flag};
# 			print "</td></tr>";
# 			push @saved_ids, $x->{id};
# 			++$n;
# 		}
# 		print "</table>";
# 		$session->{searchresults} = \@saved_ids;
# 	}
}

# run the query on Village and print out a nice table
sub print_results {
	my ($query, $table, $foundheungs) = @_;
	my $isvillage = $table eq 'Village';

	my $module = "Roots::Level::$table";
	my @results = $module->search($query);
	my $total = scalar @results;
	if (@results) {
		if (!$isvillage || $foundheungs) {
			# break up contiguous tables with some text
			my $label = lc($table);
			if ($label eq 'heung') {
				my $contains_heung = $results[0][0]{id} < 5;
				my $contains_admin = $results[-1][0]{id} == 5;
				if ($contains_heung) {
					if ($contains_admin) {
						$label .= '/admin. district';
					}
				} else {
					$label = 'admin. district';
				}
			} elsif ($label eq 'subheung2') {
				$label = 'minor subheung' ;
			}
			print "<p>Found $total $label" . ($total == 1 ? '' : 's') . ".</p>";
		}
		# first pass: figure out the rowspans for repeated elements
		my $oldrow;
		my @rowspans;
		my $maxcol = @{$results[0]} - 2; # last column doesn't need to be processed
		my @saved_ids;
		my $n = 0;
		for my $row (@results) {
			for my $i (0..$maxcol) {
				my $x = $row->[$i];
				my $oldid = $oldrow && $oldrow->[$i]{id};
				if ($x->{id} == $oldid) { # compare corresponding items of each row
					$rowspans[$i]++;
				} else {
					if ($rowspans[$i] > 1) {
						$results[$n-$rowspans[$i]][$i]{__rowspan} = $rowspans[$i];
					}
					$rowspans[$i] = 1;
				}
			}
			push @saved_ids, $row->[-1]{id} if $Roots::Util::admin;
			$oldrow = $row;
			$n++;
		}
		for my $i (0..$maxcol) {
			if ($rowspans[$i] > 1) {
				$results[$n-$rowspans[$i]][$i]{__rowspan} = $rowspans[$i];
			}
		}
		if ($Roots::Util::admin) {
			$session->{searchresults} = \@saved_ids;
		}
		
		# second pass: generate html table
		print q|<table class="search">|;
		my $thead = "<thead><tr><th>#</th><th>County</th><th>Area</th><th>Heung</th>";
		if ($table eq 'Village') {
			$thead .= "<th>Village</th>";
		} elsif ($table =~ /^Subheung/) {
			$thead .= "<th>Subheung</th>";
			if ($table eq 'Subheung2') {
				$thead .= "<th>Minor subheung</th>";
			}
		}
		$thead .= '<th>Edit</th>' if $Roots::Util::admin;
		$thead .= "</thead><tbody>\n";

		$n = 1;
		my $old_county_id;
		$oldrow = undef;
		foreach (@results) { # for each array ref...
			my $county_id = $_->[0]{id};
			if ($county_id != $old_county_id) {
				if (!defined($old_county_id) && $county_id < 5) {
					print $thead;
				} elsif ($county_id == 5) {
					if (defined($old_county_id)) {
						print qq|</tbody></table>\n&nbsp;<table class="search">|;
					}
					$thead =~ s/Area/Township/;
					$thead =~ s/Heung/Admin. Dist./;
					print $thead;
					$n = 1;
				}
				$old_county_id = $county_id;
			}
			print qq|<tr><td>$n</td>|;
			foreach my $x (@$_) {
				my $oldid = $oldrow && (shift @$oldrow)->{id};
				next if $x->{id} == $oldid;

				my $id;
				if ($surname && $x->{latlon}) {
					$id = ($county_id == 5 ? 't' : 'h') . $x->{id};
				}
				print "<td";
				my $rowspan = $x->{__rowspan};
				if ($rowspan) {
					print qq| rowspan="$rowspan">|;
					print '<div><div class="multi"';
				}
				print qq# id="$id"# if $id;
				print '>';
				$x->display_short();
				print "\x{3000}" if $x->{num}; # force the baseline for Area numbers to align by printing a CJK space
				if ($id) {
					print ' <a href="#" class="maplink">[map↑]</a>';
				}
				if ($rowspan) {
					print '</div></div>';
				}
				print "</td>";
			}
			if ($Roots::Util::admin) {
				print '<td>', Roots::Template::button('Edit', $table, $_->[-1]{id}, 'display.cgi', {searchitem=>$n});
				print "[$_->[-1]{flag}] $_->[-1]{flagnote}" if $_->[-1]{flagnote};
				print '</td>';
			}
			print "</tr>\n";
			++$n;
			$oldrow = $_;
		}
		print '</tbody>';
		print "</table>";
	} else {
		print "<p>No results found.</p>" if $isvillage;
	}
	return $total;
}

sub print_search {
	my $sort_py = $sortorder eq 'PY';
	my $show_py = $sort_py || grep {$_ eq 'py'} cookie('disp');
	my @menu;
	if ($sort_py) {
		@menu = sort {$$a[3] cmp $$b[3]} @Roots::Surnames::menu;
	} else {
		@menu = @Roots::Surnames::menu;
	}
	if ($reloaded) {
		$surname = $session->{surname};
	} else {
		$surname = $menu[$Q::surname][0] if $Q::surname != 0 && $Q::surname < @menu;
	}
	$session->{surname} = $surname; # save this in case user changes the sort order

	print "<script>";
	my @keys = qw(b5 rom py);
	for my $i (0..2) {
		print "var m_$keys[$i] = new Array(";
		print(join ",", map {'"' . $_->[$i] . '"'} @menu);
		print ");\n";
	}
	print "</script>";
	# generate js arrays here so they're sorted identically
	print <<EOF;
<script src="${Roots::Template::base}js/surnames.js"></script>
<h3>Search by surname</h3>
<form method="POST" action="$self" name="surname">
<p>Search for villages with surname 
<select name="surname" onchange="document.surname.submit()"
	style="font-size: larger">
<option value=0>Select surname...</option>
EOF

	foreach (1..$#menu) {
		my ($b5, $rom, $py) = @{$menu[$_]};
		if ($show_py) { 
			if ($sort_py) { $rom = qq#$py ($rom)# }
			else { $rom = qq#$rom ($py)# }
		}
		my $selected = $surname eq $b5 ? ' selected' : '';
		print qq#<option$selected value=$_>$rom ($b5)</option>\n#;
	}

print <<EOF;
</select>
<input type="hidden" name="btn" value="SearchSurname">
<input type="submit" value="Search"></p>
</form>
EOF

my ($b5_selected, $rom_selected, $py_selected) = ('', '', '');
for ($Q::field) {
	$b5_selected = ' selected', last if $_ eq 'b5';
	$py_selected = ' selected', last if $_ eq 'py';
	$rom_selected = ' selected';
}
my $heungs_checked = ' checked' if $Q::searchheungs;
print <<EOF;
<h3>Search by other</h3>
<form method="POST" action="$self">
Search for villages whose name

<select name="field">
<option value="b5"$b5_selected>in Chinese</option>
<option value="rom"$rom_selected>in romanization</option>
<option value="py"$py_selected>in pinyin</option>
</select>

<select name="how">
<option value="a" selected>starts with</option>
<option value="az">contains the text</option>
</select>

<input type=text name="text" size=25 maxlength=50>
<input type="hidden" name="btn" value="SearchOther">
<br>
<label><input type="checkbox" name="searchheungs"$heungs_checked>Also search heungs/admin. districts</label>
<input type="submit" value="Search">
</form>
EOF

return unless $Roots::Util::admin;

my $heung_selected = $Q::table eq 'Heung' ? ' selected' : '';
my $subheung_selected = $Q::table eq 'Subeung' ? ' selected' : '';
my $village_selected = (!defined($Q::table) || $Q::table eq 'Village') ? ' selected' : '';

print <<EOF;

<h3>Search: superuser</h3>
<form method="POST" action="$self">
<p>Search for

<select name="table">
<option$heung_selected>Heung</option>
<option$subheung_selected>Subheung</option>
<option$village_selected>Village</option>
</select>

where

<input type=text name="z" size=50 maxlength=1000 value="$Q::z">
<input type="hidden" name="btn" value="SearchAdvanced">
<input type="submit" value="Search">
</p>

</form>

EOF
}
