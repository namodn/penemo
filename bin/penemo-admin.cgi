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

if (param('pause')) {
	&pause(param('agent'));
}
elsif (param('unpause')) {
	&unpause(param('agent'));
}
else {
	die "nothing to do\n";
}



sub pause {
	my $agent = shift;

	unless (param('time')) { &get_time($agent); }
	else {
		my $paused = convert_to_fulltime();
		open (DATA, "$data_dir/$agent") or die "Cant open $data_dir/$agent : $!\n";
			my @data = <DATA>;
		close DATA;

		@data = split(/\s+/, $data[0]);

		$data[6] = '1';
		$data[7] = "$paused";
	
		open (DATA, ">>$data_dir/$agent") or die "Cant open $data_dir/$agent : $!\n";
			print join(/\t/, @data), "\n";
		close DATA;
	}
}

sub unpause {

}

sub get_data_dir {
	open(CFG, "$conf_dir/penemo.conf")
			or die "Can't open $conf_dir/penemo.conf : $!\n";
		my @file = (<CFG>);
	close CFG;

	foreach my $line (@file) {
		next if ($line =~ /^\s*#/);
		next if ($line =~ /^$/);
		chomp;

		next unless ($line =~ /^data_dir/);

		my ($name, $value) = split(' ', $line);
		return ($value);
	}
}

sub get_time {
	my $agent = shift;
	print header;
	print "<HEAD><TITLE>pause $agent</TITLE></HEAD>\n";
	print '<BODY BGCOLOR="#000000" TEXT="#AAAADD">', "\n";
	print "<FONT SIZE=5>pausing agent: $agent</FONT><BR>\n";
	print '&nbsp;<BR>', "\n";
	print 'current server time: ', "$date<BR>\n";
	print "<FORM METHOD=\"Post\" action=\"/cgi-bin/penemo-admin.cgi\">\n";
	print "<INPUT type=text name=\"agent\" value=\"$agent\" size=16><BR>\n";
	print 'for how many minutes do you wish to pause this agent?: <INPUT type=text name="time" size=5 maxlength=7><BR>', "\n";
	print '<INPUT TYPE=SUBMIT NAME=pause VALUE=pause><BR>', "\n";
	print '</FORM><BR>', "\n";
	print '</BODY>', "\n";
	print end_html;
}

sub convert_to_fulltime {
	my $time = param('time');

	

}
