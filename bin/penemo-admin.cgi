#!/usr/bin/perl -w

use strict;
use CGI qw(:standard);
use CGI::Carp;


use lib '/usr/local/share/penemo/lib/';
use penemo;

my $penemo_conf_file = '/usr/local/etc/penemo/penemo.conf';
my $agent_conf_file = '/usr/local/etc/penemo/agent.conf';

my $conf = penemo::config->load_config($penemo_conf_file, $agent_conf_file);

unless (param('agent')) {
	die "no agent specified\n";
}

my $date = `date`;
chomp $date;
$date =~ s/\s+/ /g;   # takeout any double spaces
my ($date_string, $date_delimited) = &convert_date_to_string();

if (param('pause')) {
	my $agent = param('agent');
	&pause($agent);
}
elsif (param('unpause')) {
	my $agent = param('agent');
	&unpause($agent);
}
else {
	die "nothing to do\n";
}



# sub for pausing agents.
sub pause {
	my ($agent, $global) = @_;
	unless ($global) {
		# treat global pause differently
		if (($agent =~ /\|/) && (param('time'))) { 
			&global_pause($agent); 
			exit;
		}
		if ($agent =~ /\|/) { &get_time($agent, 'global'); exit; }
	}

	# load agents data file into array
	my @data = &load_data($agent);  # load agent data into array
	
	if ($data[7] != '000000000000') {
		my $paused = convert_to_fulltime();
		# agent already paused
		unless ($global) {
			print header;
			print "<HEAD><TITLE>$agent paused</TITLE></HEAD>\n";
			print '<BODY BGCOLOR="#000000" TEXT="#AAAADD">', "\n";
			print '<CENTER>';
			print "&nbsp;<BR>\n";
			print "<FONT SIZE=2>";
		}

		print "$agent is already paused untill: $paused <BR>\n";

		unless ($global) {
			print "&nbsp;<BR>\n";
			print "If this is not showing in the agent list, it will be<BR>\n";
			print "updated the next time penemo is run.<BR>\n";
			print "</FONT>\n";
			print '</CENTER>';
			print "</BODY>\n";
			print end_html;
			exit;
		}
	}
	
	# print html form to get time to pause agent for
	unless (param('time')) { &get_time($agent); }
	else {
		my $paused = convert_to_fulltime();
		# time set, pause agent
		$data[6] = '1';
		$data[7] = $paused;
	
		&set_data($agent, @data);  # write agent data with paused info

		if ($global) { return($paused); }

		print header;
		print "<HEAD><TITLE>$agent paused</TITLE></HEAD>\n";
		print '<BODY BGCOLOR="#000000" TEXT="#AAAADD">', "\n";
		print '<CENTER>';
		print "<FONT SIZE=2>";
		print "&nbsp;<BR>\n";
		print "$agent paused untill: $paused <BR>\n";
		print "&nbsp;<BR>\n";
		print "the html will be updated the next time penemo is run.<BR>\n";
		print "</FONT>\n";
		print '</CENTER>';
		print "</BODY>\n";
		print end_html;
		exit;
	}
}

# sub to unpause agent
sub unpause {
	my $agent = shift;
	my @agents = ();

	# treat global pause differently
	if ($agent =~ /\|/) { 
		$agent =~ s/\|$//;
		$agent =~ s/^\|//;
		@agents = split(/\|/, $agent);
	}
	else {
		push @agents, $agent;
	}

	
	print header;
	print "<HEAD><TITLE>unpaused $agent</TITLE></HEAD>\n";
	print '<BODY BGCOLOR="#000000" TEXT="#AAAADD">', "\n";
	print '<CENTER>';
	print "<FONT SIZE=2>";
	print "&nbsp;<BR>\n";

	foreach $agent (@agents) {
		# load agents data into array
		my @data = &load_data($agent);

		# this unpauses agent
		$data[6] = '0';
		$data[7] = '000000000000';

		# write data back to file
		&set_data($agent, @data);

		print "$agent has been unpaused<BR>\n";
	}

	print "&nbsp;<BR>\n";
	print "the html will be updated the next time penemo is run.<BR>\n";
	print "</FONT>\n";
	print '</CENTER>';
	print "</BODY>\n";
	print end_html;
	exit;
}




#
# FUNCTIONS
#

# prints html for to get time to pause agent for.
sub get_time {
	my ($agent, $global) = @_;
	print header;
	print "<HEAD><TITLE>pause $agent</TITLE></HEAD>\n";
	print '<BODY BGCOLOR="#000000" TEXT="#AAAADD">', "\n";
	print '<CENTER>';
	print '&nbsp;<BR>', "\n";
	unless ($global) {
		print "<FONT SIZE=3><B>pausing agent: $agent</B></FONT><BR>\n";
	}
	print "<FONT SIZE=2>\n";
	print '&nbsp;<BR>', "\n";
	print 'current server time: ', "$date<BR>\n";
	print "<FORM METHOD=\"Post\" action=\"/cgi-bin/penemo-admin.cgi\">\n";
	if ($global) {
		print "<B>global pause, all agents apply.</B>\n";
	}
	print "<INPUT type=text name=\"agent\" value=\"$agent\" size=16 maxsize=999><BR>\n";
	print '&nbsp;<BR>', "\n";
	print 'for how long would you like to pause this agent?<BR>';
	print '<FONT COLOR=#44AAAA><B>format: DD:HH:MM (day:hr:min):</FONT></B> ';
	print '<INPUT type=text name="time" size=8 maxlength=10><BR>', "\n";
	print '&nbsp;<BR>', "\n";
	print '(<FONT COLOR=#44AAAA><B>e.g.</B></FONT> <FONT COLOR=#DDDDFF>30 would be 30 min. 02:30 would be 2 hours and 30 min. 10:00:25 would be 10 days, 25 min.</FONT>)<BR>';
	print '&nbsp;<BR>', "\n";
	print "</FONT><FONT SIZE=2 COLOR=#000000>\n";
	print '<INPUT TYPE=SUBMIT NAME=pause VALUE=pause><BR>', "\n";
	print '</FORM><BR>', "\n";
	print "</FONT>\n";
	print '</CENTER>';
	print '</BODY>', "\n";
	print end_html;
}

# converts unix time to YYYYMoMoDDHHMiMi
sub convert_to_fulltime {
	my $time = param('time');
	my ($year, $month, $day, $hour, $minutes) = split(/-/, $date_delimited);

	# split up submitted time
	$time =~ s/\s*//g;  # no whitespace

	my ($s_day, $s_hour, $s_min) = (00, 00, 00);
	if ($time !~ /\:/) {
		$s_min = $time;	
	}
	elsif ($time !~ /\:.*?\:/) {
		($s_hour, $s_min) = split(/\:/, $time, 2);  # get values from 'time'
	}
	elsif ($time =~ /\:.*?\:/) {
		($s_day, $s_hour, $s_min) = split(/\:/, $time, 3);  # get values from 'time'
	}
	$s_day =~ s/\D*//g;   # only digits
	$s_hour =~ s/\D*//g;  # only digits
	$s_min =~ s/\D*//g;   # only digits
	
	if ($s_min > '60') { $s_min = '60'; }

	my $calc = $minutes + $s_min;
	if ($calc >= '60') {
		$hour++;
		if ($hour >= '24') {
			$hour = $hour - 24;	
			$day++;
		}
		$minutes = $calc - 60;
	}	
	else {
		$minutes = $calc;
	}

	if ($s_hour > '12') { $s_hour = '12'; }
	$hour = $hour + $s_hour;
	$day = $day + $s_day;

	# if any are single digits add a before it
	if ($minutes =~ /^\d{1}$/) {
		$minutes = "0$minutes";
	}
	if ($hour =~ /^\d{1}$/) {
		$hour = "0$hour";
	}
	if ($day =~ /^\d{1}$/) {
		$day = "0$day";
	}
	if ($month =~ /^\d{1}$/) {
		$month = "0$month";
	}

	return ("$year$month$day$hour$minutes");
}

sub convert_date_to_string {
        my @date = split (/\s/, $date); # Split on whitespace
        my ($month, $day, $time, $year) = ($date[1], $date[2], $date[3], $date[5]);
        $month = convert_month($month);
        my ($hour, $minutes, $seconds) = split(/:/, $time);
        return ("$year$month$day$hour$minutes", "$year-$month-$day-$hour-$minutes");
}

sub convert_month {
        my $month = shift;
        if      ($month =~ /^Jan$/)     { $month = '01'; }      
        elsif   ($month =~ /^Feb$/)     { $month = '02'; }      
        elsif   ($month =~ /^Mar$/)     { $month = '03'; }      
        elsif   ($month =~ /^Apr$/)     { $month = '04'; }      
        elsif   ($month =~ /^May$/)     { $month = '05'; }      
        elsif   ($month =~ /^Jun$/)     { $month = '06'; }      
        elsif   ($month =~ /^Jul$/)     { $month = '07'; }      
        elsif   ($month =~ /^Aug$/)     { $month = '08'; }      
        elsif   ($month =~ /^Sep$/)     { $month = '09'; }      
        elsif   ($month =~ /^Oct$/)     { $month = '10'; }      
        elsif   ($month =~ /^Nov$/)     { $month = '11'; }      
        elsif   ($month =~ /^Dec$/)     { $month = '12'; }      
        return ($month);
}


# load agents data 
sub load_data {
	my $agent = shift;
	my $dir_data = $conf->get_dir_data();
	open (DATA, "$dir_data/$agent") or die "Cant open $dir_data/$agent : $!\n";
		my @data = <DATA>;
	close DATA;

	@data = split(/\s+/, $data[0]);
	return (@data);
}

sub set_data {
	my ($agent, @data) = @_;
	my $dir_data = $conf->get_dir_data();
	open (DATA, ">$dir_data/$agent") or die "Cant open $dir_data/$agent : $!\n";
		foreach my $delm (@data) {
			print DATA "$delm\t";
		}
		print DATA "\n";
	close DATA;
}


sub global_pause {
	my $agent = shift;
	$agent =~ s/\|$//;
	$agent =~ s/^\|//;
	my @agents = split(/\|/, $agent);
	my $paused = 0;

	print header;
	print "<HEAD><TITLE>global pause</TITLE></HEAD>\n";
	print '<BODY BGCOLOR="#000000" TEXT="#AAAADD">', "\n";
	print '<CENTER><FONT SIZE=2>';
	print "&nbsp;<BR>\n";
	print "all agents paused untill: ", $paused, "<BR>\n";
	print "&nbsp;<BR>\n";
	print "the html will be updated the next time penemo is run.<BR>\n";
	print "agents paused: <BR>\n";

	foreach $agent (@agents) {
		print "$agent<BR>";
		&pause($agent, 'global');	
	}

	print "</FONT>\n";
	print '</CENTER>';
	print end_html;
	exit;
}

