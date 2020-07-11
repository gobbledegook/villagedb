# File: Level.pm
# by Dominic Yu, 2002.01.20
#
# Administrative levels for the Roots database. This is where we have all
# the code to get information from the database and print it out.

package Roots::Level;

use v5.12;
use Carp;
use CGI qw/:standard label/;
use Time::HiRes qw(gettimeofday tv_interval);
use BigName;
use Roots::Util;

use Roots::Level::County;
use Roots::Level::Area;
use Roots::Level::Heung;
use Roots::Level::Village;

our (%_big, %_sql_fld_name, %_fld_label, %_ignore_override,
			$Force_STC_Convert, $ELAPSED);

$Force_STC_Convert = 1;

# mappings from internal field codes ('name', 'up_id', etc.) to other things.
# --------
# Conceptually, each of our Level objects contain certain fields (variables)
# with data. We represent these with names like 'name', 'up_id', 'markets', etc.
# Internally, however, some of these "fields" are actually complex BigName
# objects. We need to keep track of which ones these are.
# This is what %_big is for.
#
# %_sql_fld_name tells us what field name to look up in the database.
# %_fld_label tells us what to display on the web page.
#
# Notice that this data is specified at the top level, even though it contains
# subclass-specific things. That is, I define values for fields (such as map_loc)
# that only exist in subclasses. This is OK--in fact, it's easier than overriding
# these methods in subclasses--as long as we don't have duplicates to conflict
# with each other.

%_big	= ( name=>1, markets=>1, surname=>1 );	# BigName data
%_sql_fld_name =
		(	name=>'Name', up_id=>'Up_ID', id=>'ID',
			num=>'Num',
			markets=>'Markets', map_loc=>'Map_Location', latlon=>'latlon',
			surname=>'Surnames' );
%_fld_label =
		( 	name=>'Name',
			num=>'Area Num',
			markets=>'Market(s)', map_loc=>'Map Location', latlon=>'Lat/Lon',
			surname=>'Surname(s)' );

# _ignore_override: This is for our _add method.
# normally, we want text entry fields to be empty, so we tell the CGI module
# to force the entries to be blank. In this way, we ignore the override value
# passed to our _add method. Certain subclasses will want finer tuning.
# Specifically, Village wants to leave the Surname the same across entries.
%_ignore_override = ( surname=>1 );



# Class Data - these can be overriden in subclasses.
# ----------

sub table; # concrete subclasses must return name of corresponding sql table

# _fields: fields to fetch from database.
sub _fields	{ return qw/name up_id id/ } 

# _named: returns a list of the BigName fields for this class.
sub _named {
	my $self = shift;
	return grep { $_big{$_} } $self->_fields;
}

sub _addable_flds {
	my $self = shift;
	return grep { $_ ne 'id' && $_ !~ /_id$/i } $self->_fields;
}

## we may need to add a couple more, say, editable, or superuser
## to view/hide things like last_modified, or Notes, etc.


# Constructor
# -----------
sub new {
	# pass in the level type to this constructor,
	# and we'll construct an appropriate subclass
	my ($class, $table) = @_;
	if ($table) {
		my $package = "Roots::Level::$table";
		my $obj = bless {}, $package;
	
		# make sure it's a concrete subclass
		my $method = "${package}::table";
		if (defined &$method) {
			return $obj;
		}
		croak "level not implemented: $class";
	}
	
	# otherwise do the generic thing
	my $self = bless {}, $class;
	return $self;
}

sub Exists {
	my $method = "Roots::Level::$_[1]::table";
	return defined &$method;
}

# load_from_db($id)
# ------------
# This method simply loads the information from the corresponding record in
# the database.
sub load_from_db {
	my $self = shift;
	my ($id) = @_;
	my $table = $self->table();
	$id || bail("no $table id specified");
	
	my $fields = join(',', $self->query_fields) . ',Date_Modified, Created_By, Flag, FlagNote, Modified_By';
	my $sth = $dbh->prepare('SELECT ' . $fields . ' FROM ' . $table . ' WHERE ID=?');
	$sth->execute($id) or bail("Error reading from database.");
	$self->load($sth->fetchrow) || bail("$table id $id doesn't exist");
}

# query_fields([$skip_id])
# ------------
# returns array of field names for an SQL query.
# this function can be used as both a class method and an object method.
# The optional parameter $skip_id should be set to true if you want to get
# an array for an UPDATE command, where the ID is already set.
sub query_fields {
	my $self = shift;
	my ($skip_id) = @_;

	my @result;
	foreach ($skip_id ? $self->_addable_flds : $self->_fields) {
		my $name = $_sql_fld_name{$_} || $_;
		push @result, $_big{$_}
			? _name_fields($name)
			: $name;
	}
	
	return @result;
}

sub _name_fields {	# helper function for BigName fields, returns array of names
	my ($field) = @_;
	my @suffixes = ("", qw(_ROM _PY _JP _STC));
	return map {$field . $_} @suffixes;
}

# load(@data)
# ----
# in parallel with query_fields(), store the data passed in as array.
# Typically, you'll populate the object's variables with this method,
# by passing in the result you got from an SQL query.
# return false on failure
sub load {
	my $self = shift;
	return "" unless @_;
	
	for my $fld ($self->_fields) {
		$self->{$fld} = $_big{$fld} ? BigName->new(splice @_, 0, 5) : shift;
	}
	$self->{mod_time} = shift;		## for edit
	$self->{created_by} = shift;	## for delete
	$self->{flag} = shift;			## for admin
	$self->{flagnote} = shift;		## for admin
	$self->{mod_by} = shift;		## for admin

	return 1;
}

# More functions
# --------------
sub parent;

# Display Methods
# ---------------
# Each of these comes in pairs, so you can override the default behavior
# in a subclass. Override the function with the _underscore.

sub head_title {
	my $self = shift;
	return $self->{'name'}->rom();
}

# url()
# ---
# We need to know how to make links to the display script.
sub myurl {
	my $self = shift;
	my $url = url(-absolute => 1);
	my $relative_url = url(-relative => 1);
	my $base = substr($url, 0, -length($relative_url));;
	my $table = lc $self->table();
	return "${base}display.cgi/$table/$self->{id}";
}

# display_short()
# -------------
# Displays just the name, clickable.
# Override if you want anything else, like the num for Area.
sub display_short {
	my $self = shift;
	my $url = $self->myurl;
	
	print qq|<a href="$url">|;
	print $self->_short();
	print "</a>";
}

sub _short {
	my $self = shift;
	return $self->{'name'}->format_short("aka");
}

# display_long()
# ------------
# Multi-liner, clickable
sub display_long {	# clickable multi-liner
	my $self = shift;
	my $url = $self->myurl;
		
	print a({-href => $url}, $self->_long()), br(), "\n";
}

sub _long {
	my $self = shift;
	return $self->{'name'}->format_long();
}

# display_full()
# ------------
# displays all fields. not clickable.
sub display_full {	# the idea for these is that everything fits into a <td></td>
	my $self = shift;
	
	print qq|<table border=2 cellpadding=4>\n<tr>|;
	print $self->_full();
	print qq|</td></tr></table>|;
}

sub _full {
	my $self = shift;
	my @fields = $self->_addable_flds;
	shift @fields;	# throw away the first value, which we deal with shortly
	
	my $n = scalar @fields || 1; # rowpsan shouldn't be 0
	my $m = 1; # horizontal direction, we need this for admin stuff below
	$m += 2 if @fields;
	my $result = qq|<td rowspan="$n">| . $self->_long() . "</td>";
	
	# now we output the remaining fields
	while ($_ = shift @fields) {
		next if $_ eq 'latlon';
		$result .= "<th>$_fld_label{$_}</th><td>"
			. ($_big{$_}
				? $self->{$_}->format_long()
				: $self->{$_});
		if ($_ eq 'map_loc' && $self->{'latlon'}) {
			my $link = $self->latlon2url($self->{latlon});
			$result .= '<br>[<a href="' . $link . '" target="_blank">approx. location on google maps</a>]';
		}
		$result .= "</td></tr><tr>" if @fields; # if there's anything left, prepare a new row
	}
	if ($Roots::Util::admin) {
		$result .= qq|</td></tr><tr><td colspan="$m">Flag: | . $self->{flag};
		$result .= ' Note: ' . $self->{flagnote} if $self->{flagnote};
		$result .= '<br>created: ' . $self->{created_by};
		$result .= ' modified: ' . $self->{mod_by} if $self->{mod_by};
	}
	return $result;
}

# Editing Methods
# ---------------

sub display_add {	# class method, not object method
	my $class = shift;
	my $table = $class->table();
	my ($up_id, $override, $allow_ignore_errors) = @_;
	
	print "Add a new $table:";
	print start_form('POST', script_name());
	print hidden("level"), hidden("id", $up_id),
		hidden("form", "add"), hidden("addlevel", $table);

	print "<table border=0 cellpadding=5>";
	$class->_add($override);	
	
	if ($allow_ignore_errors == 1) {
		print Tr(td({-colspan=>2},
					checkbox(-name=>'error_ignore', -label=>'IGNORE ERRORS!'),
					br(),
					strong("reason/explanation:"),
					textfield('error_note','',45,255)
		));
	} elsif ($allow_ignore_errors == 2) { ## stc
		print Tr(td({-colspan=>2},
					label(checkbox(-name=>'stc_corrected', -label=>'I found an error in the book, and have corrected it')),
					br(),
					label(checkbox(-name=>'stc_ignore', -label=>'ignore STC mismatches')),
					hidden(-name=>'error_ignore'),hidden(-name=>'error_note')
		));
		
	}
	print Tr(td({-colspan=>2}, p({-align=>"center"}, 
		hidden(-name=>"btn", -default=>"Submit", -override=>1),
			# in case they don't click Submit but hit return
		submit(-name=>"dummy", -value=>"Submit") )));
	print "</table>";
	print end_form();
}

sub _add {
	my $class = shift;
	my ($proto_override) = @_;
	
	foreach ($class->_addable_flds) {
		my $label = $_fld_label{$_};
		my $override = $_ignore_override{$_} ? 0 : $proto_override;
		if ($_big{$_}) {
			print Tr(th($label), td(BigName::form_add($_, $override)));
		} else {
			print Tr(th($label),
					 td(textfield(-name=>$_, -default=>"", -size=>10,
					 			  -override=>$override))),"<BR>\n";
		}
	}
}

sub error_check_add {
	my $class = shift;
	my @result;
	
	if (param('error_ignore')) {
		return "you didn't specify a reason!" if (!param('error_note'));
		return;
	}
	
	foreach ($class->_named) {
		push @result, BigName::error_check_params($_);
	}
	foreach ($class->_addable_flds) {
		next if $_big{$_} || $_ eq 'latlon';
		push @result, "You left one of the fields blank ($_)!" if !param($_);
	}
	push @result, $class->_error_check_add();
	return @result;
}

sub _error_check_add {
	return;
	# override if necessary
}

sub stc_rom_check {
	my $class = shift;
	my @result;
	
	if (param('stc_ignore')) {
		return;
	}
	
	foreach ($class->_named) {
		push @result, BigName::stc_rom_check($_);
	}
	return @result;
}

#returns array of arrays, each row has stc, char, rom
sub stc_rom_check_short {
	my $self = shift;
	my @result;

	foreach ($self->_named) {
		push @result, $self->{$_}->stc_rom_check_short($_);
	}
	return @result;
}

sub duplicate_check {
	my $class = shift;
	
	my $up_id = param('id');
	my $name = Roots::Util::stc2b5(scalar param('namestc'));
	return 0 unless $name; # don't check for empty names
	
	my $table = $class->table();
	my $col = 'Up_ID';
	if ($table eq 'Village' && Roots::Level->Exists(scalar param('level'))) {
		$col = param('level') . '_ID';
	}
	my $count = $dbh->selectrow_array("SELECT COUNT(*) FROM $table WHERE $col=? AND Name=?", undef, $up_id, $name) // bail("duplicate check failed");
	return $count;
}

sub display_add_confirm {
	my $class = shift;
	my ($dup_count) = @_;
	
	foreach ($class->_named) {
		BigName::convert_stc($_);
	}
	
	if ($dup_count) {
		my $table = $class->table();
		print h1('Warning');
		print <<EOF;
<p>There is another $table here with the same name.
Please make sure this is not a duplicate. (For example, one heung will
usually not contain two villages with the same name, although it does
happen rarely.) If you are <strong>absolutely</strong> sure you wish
to add this entry, please click the "not a duplicate entry" checkbox below.
Otherwise, hit the "go back" button and fix your mistake.
</p>
EOF
	}
	
	print "Please verify data:<br>";

	print '<span style="font-size: 18pt">';		# make this extra-huge
	print start_form('POST', script_name());
	print hidden("addlevel"), "\n", hidden("level"), "\n", hidden("id"), "\n",
		hidden("form"), "\n",
		hidden("error_ignore"), hidden("error_note"),
		hidden("stc_ignore"), hidden("stc_corrected"),
		hidden('defaultbtn', 'Save')
		;	# using defaults from query object

	print "<table border=0 cellpadding=5>";
	$class->_add_confirm();
	
	print Tr(td({-colspan=>2},
				checkbox(-name=>'dupl',
						-value=>$dup_count,
						-label=>'Not a duplicate entry, cross-my-heart-hope-to-die')
	)) if $dup_count;
	print Tr(td({-colspan=>2},
				strong('Error Reporting:'), br(),
				checkbox(-name=>'user_flag',
						-label=>'I typed in the correct STC code, but the character is wrong/missing!'),
				br(),
				strong("other problem (specify):"),
				textfield('flag_note','', 45, 255 - length(param('error_note')))
	));
	print Tr(td({-colspan=>2}, p({-align=>"center"},
		submit(-name=>"btn", -value=>"Save", -style=>"width: 12em"), 
		submit(-name=>"btn", -value=>"Oops, Change") ))), "\n";
	print "</table>";
	print end_form();
	print '</span>';
}

sub _add_confirm {
	my $class = shift;
	
	foreach ($class->_addable_flds) {
		my $label = $_fld_label{$_};
		if ($_big{$_}) {
			print Tr(th($label), td(BigName::form_add_confirm($_)));
		} else {
			print Tr(th($label),
					 td(scalar param($_), hidden(-name=>$_))),"<BR>\n";
		}
	}
}

# takes the query object and makes a new entry in the database.
# Also, we tack on the creation date and the modified-by field,
# and the user flag and note, if any.
# see _values for some nitty-gritty detail.
sub do_add {
	my $class = shift;
	
	my $fields = join ',', $class->query_fields();
	$fields .= ", Date_Created, Created_By";
	
	bail('duplicate entry!') if ($class->duplicate_check() > param('dupl'));

	my @values = $class->_values();
	# we will return an object with this info
	my $x = $class->new;
	$x->load(@values);
	foreach (@values) {
		next if $_ eq 'LAST_INSERT_ID()';
		$_ = $dbh->quote($_);
	}
	push @values, 'NOW()', $dbh->quote($Roots::Util::auth_name);
	
	# error/flag stuff here
	# 4 params to deal with: error_ignore, error_note, user_flag, flag_note
	my ($enote, $fnote) = (scalar param('error_note'), scalar param('flag_note'));
	# combine the two notes
	my $note = param('error_ignore')
		? $enote . ($fnote ? "/$fnote" : '')
		: $fnote;
	$note = $dbh->quote($note);
	
	my $flag = 0;
	$flag += 1 if param('user_flag');
	$flag += 2 if param('error_ignore');
	$flag += 4 if param('stc_ignore');
	$flag += 8 if param('stc_corrected');
	$fields .= ", Flag, FlagNote";
	push @values, $flag, $note;
	
	my $values = join ',', @values;
	my $table = $class->table();
	my $statement = "INSERT INTO $table ($fields) VALUES ($values)";
	
	$dbh->do($statement) or bail("Couldn't add $class: " . $dbh->errstr);

	$x->{'id'} = $dbh->selectrow_array("SELECT LAST_INSERT_ID()")
		|| bail("Error during SELECT LAST_INSERT_ID()!!!");
	return $x;
}

sub _values {	# in parallel with fields(), array of values to save to db
	my $class = shift;
	my ($skip_id) = @_;
	
	my @result;
	foreach ($skip_id ? $class->_addable_flds : $class->_fields) {
		if ($_big{$_}) {
			foreach my $key (BigName::keys($_)) {
				push @result, scalar param($key);
			}
		} else {
			my $item;
			if ($_ eq 'up_id')	{ $item = param('id') }
			elsif ($_ eq 'id')	{ $item = undef }
			else 				{ $item = param($_) }
			push @result, $item;
		}
	}
	return @result;
}

sub display_edit {
	my $self = shift;
	my $table = $self->table();
	
	print p("Edit information for this $table:");
	print p("Note: changing the STC code will change the b5, pinyin, and jyutping"
			. " fields correspondingly (clobbering whatever's there already).");
	
	if ($Roots::Util::admin) {
		if (my @result = $self->stc_rom_check_short()) {
			print "<br>" . start_form(-action=>"roms.cgi", -target=>"roms") . join(',', @$_) .
				submit(-name=>"btn", -value=>'add') . hidden('b5',$_->[1]) . hidden('rom',$_->[2])
				. hidden('srcid',$self->{"id"}) . hidden('srclev',$table)	# for unsetting flag bit
				. end_form() foreach @result;
		}

	}
	
	print start_form('POST', script_name());
	print hidden(-name=>"level", -default=>$table, -override=>1),	# must override to handle Skip button
		hidden(-name=>"id", -default=>$self->{"id"}, -override=>1),
		hidden("form", "edit");
	print hidden("searchitem") if param("searchitem");

	print "<table border=0 cellpadding=5>";
	foreach ($self->_addable_flds) {
		my $label = $_fld_label{$_};
		if ($_big{$_}) {
			print Tr(th($label), td($self->{$_}->form_edit($_)));
		} else {
			print Tr(th($label),
					 td(textfield(-name=>$_, -default=>$self->{$_},
					 			  -size=>10, -override=>1 ))),"<BR>\n";
		}
	}
	if ($Roots::Util::admin) {
		my $flag = $self->{flag};
		my @flagvals = (1,2,4,8);
		my %flaglabels; @flaglabels{@flagvals} = qw(userflag ignore_error ignore_stc_mismatch stc_corrected);
		print qq|<tr><td colspan="2">|;
		print checkbox_group(-name=>'flag',
        					-values=>\@flagvals,
        					-default=>[grep { $flag & $_ } @flagvals],
        					-labels=>\%flaglabels,
        					-override=>1);
        print '<br>Flagnote: ';
		print textfield(-name=>'flagnote',-default=>$self->{flagnote},
						-size=>45, -maxlength=>255, -override=>1);
		print '<br>created: ' . $self->{created_by};
		print ' modified: ' . $self->{mod_by} if $self->{mod_by};
		print "<br>id $self->{id}";
	}
	my $searchitem_index = param("searchitem");
	my $searchitem_max = $searchitem_index ? @{$Roots::Util::session{searchresults}} : 0;
	print Tr(td({-colspan=>2},
		p({-align=>"center"}, submit(-name=>"btn", -value=>"Submit")),
		$Roots::Util::admin ? p({-align=>"center"}, submit(-name=>"btn", -value=>"Clear stc_mismatch"),
			submit(-name=>"btn", -value=>"Clear all flags and notes")) : (),
		$searchitem_index ? p({-align=>"center"},
			$searchitem_index > 1 ? submit(-name=>"btn", -value=>"Back to previous") : (),
		 	"editing $searchitem_index of $searchitem_max",
			$searchitem_index < $searchitem_max ? submit(-name=>"btn", -value=>"Skip to next") : ())
		: (),
	));
	print "</table>";
	print end_form();
	if ($table eq 'Village' && $Roots::Util::auth_name eq $self->{created_by}) {
		print '<form method="post" action="' . script_name() . '">';
		print '<input type="hidden" name="level" value="Village">';
		print '<input type="hidden" name="id" value="' . $self->{id} . '">';
		print '<input type="submit" name="btn" value="Delete">';
		print '</form>';
	}
}

sub display_edit_confirm {
	my $class = shift;
	my ($old_info) = @_;
	
	# we check the new and old STC codes. if different, clobber the other values.
	foreach ($class->_named) {
		my ($new, $old) = (scalar param($_ . 'stc'), $old_info->{$_}->stc);
		$new =~ s/\D//g;
		$old =~ s/\D//g;
		if ($new ne $old or $Force_STC_Convert) {
			BigName::convert_stc($_);
		}
	}
	
	print "Please verify data:<br>Changed values are marked with <span class=\"changed\">*asterisks*</span>";

	print '<span style="font-size: 18pt">';		# make this extra-huge
	print start_form('POST', script_name());
	print hidden("level"), "\n", hidden("id"), "\n",
		hidden("form"), "\n";	# use defaults from query object
	
	print hidden('mod_time', $old_info->{mod_time}), "\n";
	print hidden("searchitem") if param("searchitem");

	print "<table border=0 cellpadding=5>";
	# we take the new query object and the old one and compare what's changed
	$class->_edit_confirm(@_);
	
	if ($Roots::Util::admin) {
		my $flag = 0;
		$flag += $_ foreach multi_param('flag');
		print qq|<tr><td>Flag: | . $flag;
		print ' Note: ' . param('flagnote') if param('flagnote');
		param('flag', $flag);
		print hidden("flag");	## compare with old info?
		print hidden("flagnote");
	}
	print Tr(td({-colspan=>2}, p({-align=>"center"}, 
		submit(-name=>"btn", -value=>"Oops, Change"),
		submit(-name=>"btn", -value=>"Save") ))), "\n";
	print "</table>";
	print end_form();
	print '</span>';
}

sub _edit_confirm {
	my $class = shift;
	my ($old_info) = @_;
	
	foreach ($class->_addable_flds) {
		my $label = $_fld_label{$_};
		if ($_big{$_}) {
			print Tr(th($label), td(BigName::form_edit_confirm($_, $old_info->{$_})));
		} else {
			print Tr(th($label),
					 td(scalar param($_), hidden(-name=>$_))),"<BR>\n"; ## compare with old info?
		}
	}
}

sub save_edit {
	my $class = shift;
	
	my @fields = $class->query_fields(1);
	my @values = $class->_values(1);
	foreach (@values) { $_ = $dbh->quote($_); }
	
	my $table = $class->table();
	$dbh->do("START TRANSACTION") || bail("Couldn't begin work.");
	$dbh->do("SELECT * FROM $table WHERE ID=? FOR UPDATE", undef, scalar param('id')) ||
		bail('couldn\'t lock table!');
	
	my $mod_time = $dbh->selectrow_array(
			"SELECT Date_Modified FROM $table WHERE ID=" . param('id'))
		|| bail("Error getting Date_Modified!");

	if ($mod_time ne param('mod_time')) {
		$dbh->do("ROLLBACK");
		bail('this item has been modified by someone else!' . param('mod_time') . ' vs orig ' . $mod_time);
	}

	my $statement = "UPDATE $table SET ";
	bail("number of fields not equal to number of values when saving") if @values != @fields;
	foreach (@fields) {
		$statement .= ($_ . '=' . shift(@values) . ', ');
	}
	$statement .= "Modified_By=" . $dbh->quote($Roots::Util::auth_name);
	if ($Roots::Util::admin) {
		$statement .= ",Flag=" . $dbh->quote(scalar param('flag'));
		$statement .= ",FlagNote=" . $dbh->quote(scalar param('flagnote'));
	}
	
	$statement .= " WHERE ID=" . param('id');
	$dbh->do($statement)
		|| bail("Couldn't update $table: " . $dbh->errstr
								. "<br>$statement");
	$dbh->do("COMMIT") ||
		bail('couldn\'t unlock tables!');
}

# returns an array of arrays
# each "row" is an array of county,area,heung,etc.
# this method works for Heung, Village, Subheung, Subheung2
sub search {
	my ($class, $condition) = @_;

	my @tables = qw(Heung Area County); # note reversed order
	my $join = 'County JOIN Area ON Area.Up_ID=County.ID JOIN Heung ON Heung.Up_ID=Area.ID';
	my $options = " ORDER BY County.ID, Area.ID";
	my $level = $class->table();
	if ($level ne 'Heung') {
		$options .= ', Heung.ID';
		if ($level =~ /^Subheung/) {
			unshift @tables, 'Subheung';
			$join .= ' JOIN Subheung ON Subheung.Up_ID=Heung.ID';
			if ($level eq 'Subheung2') {
				$options .= ', Subheung.ID';
				unshift @tables, 'Subheung2';
				$join .= ' JOIN Subheung2 ON Subheung2.Up_ID=Subheung.ID'
			}
		} else {
			unshift @tables, 'Village';
			$join .= ' JOIN Village ON Village.Heung_ID=Heung.ID';
			if ($condition =~ /^surnames_index/) {
				$join .= ' JOIN surnames_index ON Village.ID=surnames_index.village_id';
			}
		}
	}
	if ($sortorder eq 'PY' || $sortorder eq 'ROM') {
		$options .= ", $level.Name_$sortorder";
	} else {
		$options .= ", $level.ID";
	}

	# get fld names
	my @flds;
	my %num_flds;
	for my $table (@tables) {
		my $lev = "Roots::Level::$table";
		my @tmp = $lev->query_fields; # the load() method usually takes extra metadata fields, but we can just leave those blank
		if ($Roots::Util::admin && $table eq $level) { push @tmp, qw(Date_Modified Created_By Flag) } # FlagNote Modified_By
		$num_flds{$table} = @tmp;
		@tmp = map {"$table.$_"} @tmp;
		push @flds, @tmp;
	}

	my $sth = $dbh->prepare('SELECT ' . join(',', @flds)
		. " FROM $join WHERE $condition $options"
		. ' LIMIT 1000');
	my $t0 = [gettimeofday];
	$sth->execute() or bail("Error reading from database.");
	$ELAPSED += tv_interval($t0);

	my @result;
	while (my @row = $sth->fetchrow_array()) {
		my @line;
		for my $table (@tables) {
			my $x = Roots::Level->new($table);
			$x->load(splice @row, 0, $num_flds{$table});
			unshift @line, $x; # build a row of Root::Level objects, now unreversed
		}
		push @result, \@line;
	}
	return @result;
}


1;
