#!/usr/bin/perl -w

use strict;
use CGI qw(:standard);
use CGI::Carp;

#my $conf_dir = '/usr/local/etc/penemo/';
my $conf_dir = '/home/nick/devel/penemo/conf/';

unless (param('agent')) {
	die "no agent specified\n";
}

my $data_dir = &get_data_dir();
my $date = `date`;
my ($date_string, $date_delimited) = &convert_date_to_string();
my $agent = param('agent');

if (param('pause')) {
	&pause();
}
elsif (param('unpause')) {
	&unpause();
}
else {
	die "nothing to do\n";
}



sub pause {
	my $paused = convert_to_fulltime();

	my @data = &load_data();

	if ($data[7] != '000000000000') {
		print header;
		print "<HEAD><TITLE>$agent paused</TITLE></HEAD>\n";
		print '<BODY BGCOLOR="#000000" TEXT="#AAAADD">', "\n";
		print "&nbsp;<BR>\n";
		print "$agent is already paused untill: $paused <BR>\n";
		print "&nbsp;<BR>\n";
		print "If this is not showing in the agent list, it will be<BR>\n";
		print "updated the next time penemo is run.<BR>\n";
		print "</BODY>\n";
		print end_html;
		exit;
	}
	
	unless (param('time')) { &get_time($agent); }
	else {
		$data[6] = '1';
		$data[7] = $paused;
	
		&set_data(@data);

		print header;
		print "<HEAD><TITLE>$agent paused</TITLE></HEAD>\n";
		print '<BODY BGCOLOR="#000000" TEXT="#AAAADD">', "\n";
		print "&nbsp;<BR>\n";
		print "$agent paused till: $paused <BR>\n";
		print "&nbsp;<BR>\n";
		print "html display will be updated next time penemo is run.<BR>\n";
		print "</BODY>\n";
		print end_html;
		exit;
	}
}

sub unpause {
	my @data = &load_data();

	$data[6] = '0';
	$data[7] = '000000000000';

	&set_data(@data);

	print header;
	print "<HEAD><TITLE>unpaused $agent</TITLE></HEAD>\n";
	print '<BODY BGCOLOR="#000000" TEXT="#AAAADD">', "\n";
	print "&nbsp;<BR>\n";
	print "$agent has been unpaused<BR>\n";
	print "&nbsp;<BR>\n";
	print "html display will be updated next time penemo is run.<BR>\n";
	print "</BODY>\n";
	print end_html;
	exit;
}




#
# FUNCTIONS
#
#

sub get_data_dir {
	open(CFG, "$conf_dir/penemo.conf")
			or die "Can't open $conf_dir/penemo.conf : $!\n";
		my @file = <CFG>;
	close CFG;

	foreach my $line (@file) {
		next if ($line =~ /^\s*#/);
		next if ($line =~ /^$/);
		chomp $line;

		next unless ($line =~ /^data_dir/);

		my ($name, $value) = split(' ', $line);
		return ($value);
	}
}

sub get_time {
	print header;
	print "<HEAD><TITLE>pause $agent</TITLE></HEAD>\n";
	print '<BODY BGCOLOR="#000000" TEXT="#AAAADD">', "\n";
	print "<FONT SIZE=5>pausing agent: $agent</FONT><BR>\n";
	print '&nbsp;<BR>', "\n";
	print 'current server time: ', "$date<BR>\n";
	print "<FORM METHOD=\"Post\" action=\"/cgi-bin/penemo-admin.cgi\">\n";
	print "<INPUT type=text name=\"agent\" value=\"$agent\" size=16><BR>\n";
	print 'enter the number minutes you wish to pause this agent? (max: 60): <INPUT type=text name="time" size=2 maxlength=2><BR>', "\n";
	print '<INPUT TYPE=SUBMIT NAME=pause VALUE=pause><BR>', "\n";
	print '</FORM><BR>', "\n";
	print '</BODY>', "\n";
	print end_html;
}

sub convert_to_fulltime {
	my $time = param('time');
	my ($year, $month, $day, $hour, $minutes) = split(/-/, $date_delimited);
	my $calc = $day + $time;
	if ($calc >= '60') {
		$hour++;
		$minutes = $calc - 60;
	}	
	else {
		$minutes = $calc;
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


sub load_data {
	open (DATA, "$data_dir/$agent") or die "Cant open $data_dir/$agent : $!\n";
		my @data = <DATA>;
	close DATA;

	@data = split(/\s+/, $data[0]);
	return (@data);
}

sub set_data {
	my (@data) = @_;
	open (DATA, ">$data_dir/$agent") or die "Cant open $data_dir/$agent : $!\n";
		foreach my $delm (@data) {
			print DATA "$delm\t";
		}
		print DATA "\n";
	close DATA;
}
