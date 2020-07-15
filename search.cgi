#!/usr/bin/perl
use v5.12;
use lib '.';
use Roots::Util;
use Roots::Template;
use Roots::Level;
use utf8;
binmode(STDOUT, ":utf8");
use CGI qw(-utf8 :standard);
my (@menu);

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

# save this so login.cgi and options.cgi know where to go back to
$session->{'page'}	= $self . '?reload=1';
$session->{'query'} = $q;


my $dbh = Roots::Util::do_connect();


# print headers
print header(-type=>'text/html; charset=utf-8', $cookie ? (-cookie=>$cookie) : ());
Roots::Template::print_head('Search', $auth_name);

# display stuff
print h1("Village DB Search");

my %actions = ( SearchSurname=>\&do_search_by_surname,
				SearchOther=>\&do_search_other,
				SearchAdvanced=>\&do_search_superuser,
				 );

my $action = $actions{$btn} || \&do_search_screen;
&$action;

$dbh->disconnect;
print hr, qq|\n<div class="admin">|;
print "VillageDB $Roots::Util::VERSION by Dominic Yu.\n";
#print qq#| <a href="about.html">About</a>#;
print "</div>";
print qq#<script>window.history.replaceState(null,"","$self")</script># if $reloaded;
Roots::Template::print_tail();
tied(%$session)->save;


#subroutines

sub do_search_screen {
	print_search();
}

sub do_search_by_surname {
	print_search();
	return unless $Q::surname != 0 && $Q::surname < @menu;
	print "<hr>";
	
	my $surname = $menu[$Q::surname][0];

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
	print "<p>Searching for " . ($Q::searchheungs ? 'heungs and ' : '') . "villages whose name"
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
# 		my $fields = join(',', $x->query_fields(), qw(Date_Modified Created_By Flag FlagNote Modified_By));
# 		my $sth = $dbh->prepare("SELECT $fields FROM $Q::table WHERE $Q::z");
# 		$sth->execute() or bail("Error reading from database.");
# 		my @saved_ids;
# 		my $n = 1;
# 		print q|<table class="search" cellspacing=0>|;
# 		while (my @ary = $sth->fetchrow_array()) {
# 			print "<tr><td>$n</td><td>";
# 			$x->load(@ary);
# 			$x->display_short();
# 			print "</td><td>";
# 			print qq|<form method="post" action="display.cgi">($x->{flag})
# <input type="hidden" name="level" value="$Q::table">
# <input type="hidden" name="id" value="$x->{id}">
# <input type="hidden" name="searchitem" value="$n">
# <input type="submit" name="btn" value="Edit"></form>|;
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
			$label = 'minor subheung' if $label eq 'subheung2';
			print "<p>Found $total $label" . ($total == 1 ? '' : 's') . ".</p>";
		}
		print q|<table class="search" cellspacing=0>|;
		my $thead = "<thead><th>#</th><th>County</th><th>Area</th><th>Heung</th>";
		if ($table eq 'Village') {
			$thead .= "<th>Village</th>";
		} elsif ($table =~ /^Subheung/) {
			$thead .= "<th>Subheung</th>";
			if ($table eq 'Subheung2') {
				$thead .= "<th>Minor subheung</th>";
			}
		}
		$thead .= '<th>Edit</th>' if $Roots::Util::admin;
		$thead .= "</thead>\n";
		print $thead;

		my $n = 1;
		my $oldref;
		my @saved_ids;
		foreach (@results) { # for each array ref...
			my $hilite = ($n % 5 || $total < 10) ? '' : ' class="hilite"';
			print qq|<tr$hilite><td class="num">|, $n, "</td>";
			foreach my $x (@$_) {
				print "<td>";
				my $oldid = $oldref && (shift @$oldref)->{id};
				if ($x->{id} == $oldid) { # compares corresponding items of each row
					print '"';
				} else {
					$x->display_short()
				}
				print "</td>";
			}
			if ($Roots::Util::admin) {
				print '<td>', Roots::Template::button('Edit', $table, $_->[-1]{id}, 'display.cgi', {searchitem=>$n});
				print "[$_->[-1]{flag}] $_->[-1]{flagnote}" if $_->[-1]{flag};
				print '</td>';
			}
			print "</tr>\n";
			++$n;
			$oldref = $_; # save this row
			push @saved_ids, $_->[-1]{id};
		}
		print "</table>";
		if ($Roots::Util::admin) {
			$session->{searchresults} = \@saved_ids;
		}
	} else {
		print "<p>No results found.</p>" if $isvillage;
	}
	return $total;
}

sub print_search {
	my $sort_py = $sortorder eq 'PY';
	my $show_py = $sort_py || grep {$_ eq 'py'} @BigName::displayed;
	if ($sort_py) {
		@menu = sort {$$a[3] cmp $$b[3]} @menu;
	}
	print <<EOF;
<h3>Search by surname</h3>
<script type="text/javascript" language="javascript">
<!--
EOF
	my @keys = qw(b5 rom py);
	for my $i (0..2) {
		print "var m_$keys[$i] = new Array(";
		print(join ",", map {'"' . $_->[$i] . '"'} @menu);
		print ");\n";
	}
	print <<EOF;
function resetMenu() {
	var n = document.surname.surname.options; var s;
	var show_py = document.cookie.indexOf("&py") != -1;
	var sort_py = document.cookie.indexOf("sort=py") != -1;
	for (i=1; i<n.length; i++) {
		if (show_py) {
			if (sort_py) s = m_py[i] + ' (' + m_rom[i] + ')';
			else s = m_rom[i] + ' (' + m_py[i] + ')';
		} else s = m_rom[i];
		n[i].text = s + ' (' + m_b5[i] + ')';
	}
}
//-->
</script>
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
		my $selected = $Q::surname == $_ ? ' selected' : '';
			# this is why we don't use 0, so we don't accidentally select the first surname
		print qq#<option$selected value=$_>$rom ($b5)</option>\n#;
	}

print <<EOF;
</select>
<input type="hidden" name="btn" value="SearchSurname">
<input type="submit" value="Search"></p>
</form>
EOF

# <select name="field">
# <option>Heung</option>
# <option>Subheung</option>
# <option>Subheung2</option>
# <option>Village</option>
# </select>

my ($b5_selected, $rom_selected, $py_selected) = ('', '', '');
for ($Q::field) {
	$b5_selected = ' selected', last if $_ eq 'b5';
	$py_selected = ' selected', last if $_ eq 'py';
	$rom_selected = ' selected';
}
my $heungs_checked = ' checked' if $Q::searchheungs;
print <<EOF;
<h3>Search by other</h3>
<form method="POST" action="$self" style="display: inline;">
Search for villages whose name

<select name="field">
<option value="b5"$b5_selected>in Chinese</option>
<option value="rom"$rom_selected>in Cantonese romanization</option>
<option value="py"$py_selected>in pinyin</option>
</select>

<select name="how">
<option value="a" selected>starts with</option>
<option value="az">contains the text</option>
</select>

<input type=text name="text" size=25 maxlength=50>
<input type="hidden" name="btn" value="SearchOther">
<br>
<label><input type="checkbox" name="searchheungs"$heungs_checked>Also search heungs</label>
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

BEGIN { # stick this here so it's out of the way
# This list of surnames could in theory be generated on the fly, but
# having it hard coded here saves us an SQL call and allows us to tweak things
# like the order of the surnames in cases where, e.g., Wong 黃 is much more
# common than Wong 王 so we list it first. At this point most of the data has
# been entered, so if any new surnames pop up we can add them here by hand.
@menu = (['dummy'],
['區', 'Au', 'Ōu', 'ou1'],
['歐', 'Au', 'Ōu', 'ou1'],
['歐陽', 'Au Yeung', 'Ōuyáng', 'ou1 yang2'],
['鮑', 'Bau, Pao', 'Bào', 'bao4'],
['陳', 'Chan, Chin', 'Chén', 'chen2'],
['巢', 'Chao', 'Cháo', 'chao2'],
['周', 'Chau, Chow', 'Zhōu', 'zhou1'],
['鄭', 'Cheng', 'Zhèng', 'zheng4'],
['卓', 'Cheuk', 'Zhuó', 'zhuo2'],
['張', 'Cheung', 'Zhāng', 'zhang1'],
['蔣', 'Chiang', 'Jiǎng', 'jiang3'],
['錢', 'Chien, Chin', 'Qián', 'qian2'],
['戚', 'Chik', 'Qī', 'qi1'],
['赤', 'Chik', 'Chì', 'chi4'],
['秦', 'Chin', 'Qín', 'qin2'],
['程', 'Ching', 'Chéng', 'cheng2'],
['趙', 'Chiu, Chu, Jew', 'Zhào', 'zhao4'],
['曹', 'Cho, Tso', 'Cáo', 'cao2'],
['蔡', 'Choi, Toy, Tsoi', 'Cài', 'cai4'],
['鄒', 'Chow', 'Zōu', 'zou1'],
['朱', 'Chu, Gee', 'Zhū', 'zhu1'],
['崔', 'Chui', 'Cuī', 'cui1'],
['鍾', 'Chung', 'Zhōng', 'zhong1'],
['戴', 'Dai, Tai', 'Dài', 'dai4'],
['謝', 'Der, Tse', 'Xiè', 'xie4'],
['范', 'Fan', 'Fàn', 'fan4'],
['樊', 'Fan', 'Fán', 'fan2'],
['霍', 'Fok', 'Huò', 'huo4'],
['方', 'Fong', 'Fāng', 'fang1'],
['鄺', 'Fong, Kwong', 'Kuàng', 'kuang4'],
['傅', 'Fu', 'Fù', 'fu4'],
['馮', 'Fung', 'Féng', 'feng2'],
['甄', 'Gin, Yan', 'Zhēn', 'zhen1'],
['夏', 'Ha', 'Xià', 'xia4'],
['侯', 'Hau', 'Hóu', 'hou2'],
['何', 'Ho', 'Hé', 'he2'],
['賀', 'Ho', 'Hè', 'he4'],
['譚', 'Hom, Tam', 'Tán', 'tan2'],
['康', 'Hong', 'Kāng', 'kang1'],
['許', 'Hui', 'Xǔ', 'xu3'],
['熊', 'Hung', 'Xióng', 'xiong2'],
['洪', 'Hung', 'Hóng', 'hong2'],
['詹', 'Jim', 'Zhān', 'zhan1'],
['甘', 'Kam', 'Gān', 'gan1'],
['金', 'Kam', 'Jīn', 'jin1'],
['簡', 'Kan', 'Jiǎn', 'jian3'],
['高', 'Ko', 'Gāo', 'gao1'],
['江', 'Kong', 'Jiāng', 'jiang1'],
['古', 'Ku', 'Gǔ', 'gu3'],
['顧', 'Ku', 'Gù', 'gu4'],
['龔', 'Kung', 'Gōng', 'gong1'],
['關', 'Kwan', 'Guān', 'guan1'],
['郭', 'Kwok', 'Guō', 'guo1'],
['黎', 'Lai', 'Lí', 'li2'],
['賴', 'Lai', 'Lài', 'lai4'],
['林', 'Lam, Lum', 'Lín', 'lin2'],
['藍', 'Lam', 'Lán', 'lan2'],
['劉', 'Lau', 'Liú', 'liu2'],
['李', 'Lee', 'Lǐ', 'li3'],
['利', 'Lee', 'Lì', 'li4'],
['梁', 'Leung', 'Liáng', 'liang2'],
['連', 'Lin', 'Lián', 'lian2'],
['練', 'Lin', 'Liàn', 'lian4'],
['凌', 'Ling', 'Líng', 'ling2'],
['廖', 'Liu', 'Liào', 'liao4'],
['盧', 'Lo', 'Lú', 'lu2'],
['勞', 'Lo', 'Láo', 'lao2'],
['羅', 'Lo, Lor', 'Luó', 'luo2'],
['駱', 'Lok', 'Luò', 'luo4'],
['洛', 'Lok', 'Luò', 'luo4'],
['雷', 'Louie, Lui', 'Léi', 'lei2'],
['呂', 'Lui', 'Lǚ', 'lv3'],
['陸', 'Luk', 'Lù', 'lu4'],
['龍', 'Lung', 'Lóng', 'long2'],
['馬', 'Ma, Mar', 'Mǎ', 'ma3'],
['麥', 'Mak', 'Mài', 'mai4'],
['文', 'Man, Mun', 'Wén', 'wen2'],
['孟', 'Mang', 'Mèng', 'meng4'],
['繆', 'Mau', 'Móu', 'mou2'],
['巫', 'Mo', 'Wū', 'wu1'],
['毛', 'Mo', 'Máo', 'mao2'],
['莫', 'Mok', 'Mò', 'mo4'],
['梅', 'Moy', 'Méi', 'mei2'],
['伍', 'Ng', 'Wǔ', 'wu3'],
['吳', 'Ng', 'Wú', 'wu2'],
['倪', 'Ngai', 'Ní', 'ni2'],
['魏', 'Ngai', 'Wèi', 'wei4'],
['顏', 'Ngan', 'Yán', 'yan2'],
['敖', 'Ngo', 'Áo', 'ao2'],
['寧', 'Ning', 'Níng', 'ning2'],
['聶', 'Nip', 'Niè', 'nie4'],
['柯', 'Or', 'Kē', 'ke1'],
['白', 'Pak', 'Bái', 'bai2'],
['彭', 'Pang', 'Péng', 'peng2'],
['潘', 'Poon, Pun', 'Pān', 'pan1'],
['盤', 'Poon', 'Pán', 'pan2'],
['辛', 'San, Sun', 'Xīn', 'xin1'],
['司徒', 'Seto', 'Sītú', 'si1 tu2'],
['施', 'She', 'Shī', 'shi1'],
['石', 'Shek', 'Shí', 'shi2'],
['佘', 'Sher', 'Shé', 'she2'],
['岑', 'Shum', 'Cén', 'cen2'],
['單', 'Sin', 'Shàn', 'shan4'],
['冼', 'Sin', 'Shěng', 'sheng3'],
['薛', 'Sit', 'Xuē', 'xue1'],
['蕭', 'Siu', 'Xiāo', 'xiao1'],
['蘇', 'So', 'Sū', 'su1'],
['孫', 'Suen, Sun', 'Sūn', 'sun1'],
['沈', 'Sum', 'Chén', 'chen2'],
['宋', 'Sung', 'Sòng', 'song4'],
['談', 'Tam', 'Tán', 'tan2'],
['鄧', 'Tang', 'Dèng', 'deng4'],
['丁', 'Ting', 'Dīng', 'ding1'],
['湯', 'Tong', 'Tāng', 'tang1'],
['唐', 'Tong', 'Táng', 'tang2'],
['曾', 'Tsang', 'Zēng', 'zeng1'],
['徐', 'Tsui', 'Xú', 'xu2'],
['衛', 'Wai, Wei', 'Wèi', 'wei4'],
['溫', 'Wan, Won', 'Wēn', 'wen1'],
['尹', 'Wan', 'Yǐn', 'yin3'],
['屈', 'Wat', 'Qū', 'qu1'],
['黃', 'Wong', 'Huáng', 'huang2'],
['王', 'Wong', 'Wáng', 'wang2'],
['胡', 'Woo, Wu', 'Hú', 'hu2'],
['任', 'Yam', 'Rèn', 'ren4'],
['殷', 'Yan', 'Yīn', 'yin1'],
['丘', 'Yau', 'Qiū', 'qiu1'],
['邱', 'Yau', 'Qiū', 'qiu1'],
['余', 'Yee, Yu', 'Yú', 'yu2'],
['楊', 'Yeung', 'Yáng', 'yang2'],
['嚴', 'Yim', 'Yán', 'yan2'],
['英', 'Ying', 'Yīng', 'ying1'],
['葉', 'Yip', 'Yè', 'ye4'],
['姚', 'Yiu', 'Yáo', 'yao2'],
['饒', 'Yiu', 'Ráo', 'rao2'],
['茹', 'Yu', 'Rú', 'ru2'],
['阮', 'Yuen', 'Ruǎn', 'ruan3'],
['袁', 'Yuen', 'Yuán', 'yuan2'],
['遠', 'Yuen', 'Yuǎn', 'yuan3'],
['翁', 'Yung', 'Wēng', 'weng1'],
['容', 'Yung', 'Róng', 'rong2'],
);
}
