#  modules/penemo/agent/snmp/ucd.pm 
#  Copyright (C) 2000 Nick Jennings
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
#
#  This program is developed and maintained by Nick Jennings.
# Contact Information:
#
#    Nick Jennings                 nick@namodn.com
#    PMB 377                       http://nick.namodn.com
#    4096 Piedmont Ave.
#    Oakland, CA 94611
#
#  penemo homepage : http://www.communityprojects.org/apps/penemo/
#
#

package penemo::agent::snmp::ucd;
use strict;

sub new {
	my ($class, %args) = @_;
	
	my $ref = {
		ip	    => $args{ip},
		community   => $args{community},
		message	    => '',
		status	    => '',
		html	    => '',
		dir_ucd_bin => $args{dir_ucd_bin},
	};

	bless $ref, $class;
}


# functions to retrieve values for internal methods.
#
sub _get_dir_ucd_bin { $_[0]->{dir_ucd_bin} }
sub _get_community { $_[0]->{community} }
sub _get_ip { $_[0]->{ip} }

sub status { $_[0]->{status}; } 
sub message { $_[0]->{message}; } 
sub html { $_[0]->{html}; } 
sub walk { $_[0]->{walk}; } 

sub poll {
	my $self = shift;
	my $ip = $self->_get_ip();
	my $community = $self->_get_community();
	my $dir_ucd_bin = $self->_get_dir_ucd_bin();
	my $snmpwalk = "$dir_ucd_bin/snmpwalk";
	my %snmp;

	my @walk = `$snmpwalk $ip $community ucd`;

	if ($#walk <= '1') { 
		$self->{status} = '0';
		$self->{messages} = "agent didn't respond to poll.\n"; 
		exit; 
	}
	else {
		$self->{walk} = "@walk";
	}
	
	foreach my $line (@walk) { 
		chomp $line; 
		my ($obj, $value) = split(' = ', $line); 
		$snmp{'ucd'}{$obj} = $value; 
	} 

	my @miberrors = ();      # stack of errors in snmp mib
	my @html = ();	         # html output
	my $ok_light = penemo::core->html_image('agent', 'ok');
	my $bad_light = penemo::core->html_image('agent', 'bad');
	# print html data

	#
	# Processes
	#

	my $prnum = 1;
	while ()
	{
		if ($snmp{'ucd'}{'enterprises.ucdavis.prTable.prEntry.prIndex.' . $prnum})
		{
			$prnum++;
		}
		else
		{
			$prnum = $prnum - 1;
			last;
		}
	} 
	push @html, "<FONT COLOR=\"#BBBB66\">Number of Monitored Daemons: </FONT>"; 
	push @html, "<FONT COLOR=\"#AAAAAA\">$prnum</FONT><BR>\n"; 
	push @html,  "&nbsp;<BR>\n";

	for (my $c = '1'; $c <= $prnum; $c++) { 
		push @html, "<FONT COLOR=\"#AA22AA\">Number: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">$c</FONT><BR>\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Name: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.prTable.prEntry.prNames.' . $c}</FONT><BR>\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Min. Number of Processes: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.prTable.prEntry.prMin.' . $c}</FONT> &nbsp &nbsp &nbsp\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Max. Number of Processes: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.prTable.prEntry.prMax.' . $c}</FONT><BR>\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Current Number of Processes: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.prTable.prEntry.prCount.' . $c}</FONT><BR>\n"; 

		if ($snmp{'ucd'}{'enterprises.ucdavis.prTable.prEntry.prErrorFlag.' . $c} == '1') { 
			push @html, "$bad_light\n"; 
			my $daemon = $snmp{'ucd'}{'enterprises.ucdavis.prTable.prEntry.prNames.' . $c}; 
			my $errormsg = $snmp{'ucd'}{'enterprises.ucdavis.prTable.prEntry.prErrMessage.' . $c}; 
			# Problem with $daemon daemon on IP: $ip 
			push @miberrors, "$errormsg\n"; 
		} 
		else { 
			push @html, "$ok_light\n"; 
		} 
		push @html, "<FONT COLOR=\"#AA22AA\">Problem with Daemon: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.prTable.prEntry.prErrorFlag.' . $c}</FONT><BR>\n"; 
		if ($snmp{'ucd'}{'enterprises.ucdavis.prTable.prEntry.prErrMessage.' . $c}) { 
			push @html, "<FONT COLOR=\"#AA22AA\">Error Message: </FONT>\n"; 
			push @html, "<FONT COLOR=\"#AAAAAA\">"; 
			push @html, "$snmp{'ucd'}{'enterprises.ucdavis.prTable.prEntry.prErrMessage.' . $c}</FONT><BR>\n"; 
		} 
		push @html, "&nbsp;<BR>\n"; 
	} 
	push @html, "&nbsp;<BR>\n";

	#
	# Memory
	#

	push @html, "<FONT COLOR=\"#BBBB66\">Memory</FONT><BR>\n";
	push @html, "&nbsp;<BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">Total Swap: </FONT>\n";
	push @html, "<FONT COLOR=\"#AAAAAA\">";
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.memory.memTotalSwap.0'}</FONT> &nbsp &nbsp &nbsp\n";
	push @html, "<FONT COLOR=\"#AA22AA\">Available Swap: </FONT>\n";
	push @html, "<FONT COLOR=\"#AAAAAA\">";
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.memory.memAvailSwap.0'}</FONT><BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">Total Physical: </FONT>\n";
	push @html, "<FONT COLOR=\"#AAAAAA\">";
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.memory.memTotalReal.0'}</FONT> &nbsp &nbsp &nbsp\n";
	push @html, "<FONT COLOR=\"#AA22AA\">Available Physical: </FONT>\n";
	push @html, "<FONT COLOR=\"#AAAAAA\">";
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.memory.memAvailReal.0'}</FONT><BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">Total Available: </FONT>\n";
	push @html, "<FONT COLOR=\"#AAAAAA\">";
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.memory.memTotalFree.0'}</FONT><BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">Total Shared: </FONT>\n";
	push @html, "<FONT COLOR=\"#AAAAAA\">";
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.memory.memShared.0'}</FONT><BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">Total Buffered: </FONT>\n";
	push @html, "<FONT COLOR=\"#AAAAAA\">";
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.memory.memBuffer.0'}</FONT><BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">Total Cache: </FONT>\n";
	push @html, "<FONT COLOR=\"#AAAAAA\">";
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.memory.memCached.0'}</FONT><BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">Minimum Swap Allowed: </FONT>\n";
	push @html, "<FONT COLOR=\"#AAAAAA\">";
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.memory.memMinimumSwap.0'}</FONT><BR>\n";
	 
	if ($snmp{'ucd'}{'enterprises.ucdavis.memory.memSwapError.0'} == '1') { 
		push @html, "$bad_light\n"; 
		my $errormsg = $snmp{'ucd'}{'enterprises.ucdavis.memory.memSwapErrorMsg.0'}; 
		# Minimum available swap exceded for IP: $ip 
		push @miberrors, "$errormsg\n"; 
	} 
	else { 
		push @html, "$ok_light\n"; 
	} 
	push @html, "<FONT COLOR=\"#AA22AA\">Swap Error: </FONT>\n"; 
	push @html, "<FONT COLOR=\"#AAAAAA\">"; 
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.memory.memSwapError.0'}</FONT><BR>\n"; 

	if ($snmp{'ucd'}{'enterprises.ucdavis.memory.memSwapMsg.0'}) { 
		push @html, "<FONT COLOR=\"#AA22AA\">Swap Error Message: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.memory.memSwapErrorMsg.0'}</FONT><BR>\n"; 
	} 
	push @html, "&nbsp;<BR>\n"; 
	push @html, "&nbsp;<BR>\n";


	#
	# Disk
	#
	
	my $dsknum = 1;
	while () { 
		if ($snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskIndex.' . $dsknum}) { 
			$dsknum++; 
		} 
		else { 
			$dsknum = $dsknum - 1; 
			last; 
		} 
	} 
	push @html, "<FONT COLOR=\"#BBBB66\">Number of Monitored Disks: </FONT>"; 
	push @html, "<FONT COLOR=\"#AAAAAA\">$dsknum</FONT><BR>\n"; 
	push @html, "&nbsp;<BR>\n";


	for (my $c = '1'; $c <= $dsknum; $c++) { 
		push @html, "<FONT COLOR=\"#AA22AA\">Mount Point: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskPath.' . $c}</FONT><BR>\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Device: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskDevice.' . $c}</FONT><BR>\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Minimum Free Space Allowed: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 

		if ($snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskMinimum.' . $c} == '-1') { 
			push @html, "$snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskMinPercent.' . $c} %</FONT><BR>\n"; 
		} 
		else { 
			push @html, "$snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskMinimum.' . $c} Kb</FONT><BR>\n"; 
		} 
		push @html, "<FONT COLOR=\"#AA22AA\">Total Disk Size: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskTotal.' . $c}</FONT><BR>\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Available: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskAvail.' . $c}</FONT>&nbsp &nbsp &nbsp\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Used: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskUsed.' . $c}</FONT> &nbsp\n"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskPercent.' . $c} %<BR>\n"; 

		if ($snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskErrorFlag.' . $c} == '1') { 
			push @html, "$bad_light\n"; 
			my $errormsg = $snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskErrorMsg.' . $c}; 
			# Disk error on IP: $ip 
			push @miberrors, "$errormsg\n"; 
		} 
		else { 
			push @html, "$ok_light\n"; 
		} 
		push @html, "<FONT COLOR=\"#AA22AA\">Error Flag: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskErrorFlag.' . $c}</FONT><BR>\n"; 
		if ($snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskErrorMsg.' . $c}) { 
			push @html, "<FONT COLOR=\"#AA22AA\">Error Message: </FONT>\n"; 
			push @html, "<FONT COLOR=\"#AAAAAA\">"; 
			push @html, "$snmp{'ucd'}{'enterprises.ucdavis.dskTable.dskEntry.dskErrorMsg.' . $c}</FONT><BR>\n"; 
		} 
		push @html, "&nbsp;<BR>\n";
		push @html, "&nbsp;<BR>\n"; 
	} 
	push @html, "&nbsp;<BR>\n"; 


	# 
	# Load Average 
	# 

	my $lanum = 3; 
	push @html, "<FONT COLOR=\"#BBBB66\">Load Average</FONT><BR>"; 
	push @html, "&nbsp;<BR>\n";

	for (my $c = '1'; $c <= $lanum; $c++) { 
		push @html, "<FONT COLOR=\"#AA22AA\">Load Name: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.laTable.laEntry.laNames.' . $c}</FONT><BR>\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Current Load Average: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.laTable.laEntry.laLoad.' . $c}</FONT><BR>\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Max Load Avg. Allowed: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.laTable.laEntry.laConfig.' . $c}</FONT><BR>\n"; 

		if ($snmp{'ucd'}{'enterprises.ucdavis.laTable.laEntry.laErrorFlag.' . $c} == '1') { 
			push @html, "$bad_light\n"; 
			my $errormsg = $snmp{'ucd'}{'enterprises.ucdavis.laTable.laEntry.laErrorMessage.' . $c}; 
			# Load Average error on IP: $ip 
			push @miberrors, "$errormsg\n"; 
		} 
		else { 
			push @html, "$ok_light\n"; 
		} 
		push @html, "<FONT COLOR=\"#AA22AA\">Error Flag: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.laTable.laEntry.laErrorFlag.' . $c}</FONT><BR>\n"; 
		if ($snmp{'ucd'}{'enterprises.ucdavis.laTable.laEntry.laErrMessage.' . $c}) { 
			push @html, "<FONT COLOR=\"#AA22AA\">Error Message: </FONT>\n"; 
			push @html, "<FONT COLOR=\"#AAAAAA\">"; 
			push @html, "$snmp{'ucd'}{'enterprises.ucdavis.laTable.laEntry.laErrMessage.' . $c}</FONT><BR>\n"; 
		} 
		push @html, "&nbsp;<BR>\n"; 
	} 
	push @html, "&nbsp;<BR>\n"; 


	#
	# System Stats
	#

	push @html, "<FONT COLOR=\"#BBBB66\">System Stats</FONT><BR>\n";
	push @html, "&nbsp;<BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">Memory Swapped in from Disk: </FONT>\n";
	push @html, "<FONT COLOR=\"#AAAAAA\">";
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.systemStats.ssSwapIn.0'} kB/s</FONT> &nbsp &nbsp\n";
	push @html, "<FONT COLOR=\"#AA22AA\">Out: </FONT>\n";
	push @html, "<FONT COLOR=\"#AAAAAA\">";
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.systemStats.ssSwapIn.0'} kB/s</FONT><BR>\n";
 
	if ($snmp{'ucd'}{'enterprises.ucdavis.systemStats.sysIOSent.0'}) { 
		push @html, "<FONT COLOR=\"#AA22AA\">Number of Blocks Sent to a Block Device: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.systemStats.sysIOSent.0'}</FONT> &nbsp &nbsp &nbsp\n"; 
	} 
	if ($snmp{'ucd'}{'enterprises.ucdavis.systemStats.sysIOReceive.0'}) { 
		push @html, "<FONT COLOR=\"#AA22AA\">Out: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'ucd'}{'enterprises.ucdavis.systemStats.ssIOReceive.0'}</FONT><BR>\n"; 
	} 
	push @html, "<FONT COLOR=\"#AA22AA\">Interrupts: </FONT>\n"; 
	push @html, "<FONT COLOR=\"#AAAAAA\">"; 
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.systemStats.ssSysInterrupts.0'} p/s</FONT><BR>\n"; 
	push @html, "<FONT COLOR=\"#AA22AA\">Context Switchess: </FONT>\n"; 
	push @html, "<FONT COLOR=\"#AAAAAA\">"; 
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.systemStats.ssSysContext.0'} p/s</FONT><BR>\n"; 
	push @html, "<FONT COLOR=\"#AA22AA\">User CPU Usage: </FONT>\n"; 
	push @html, "<FONT COLOR=\"#AAAAAA\">"; 
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.systemStats.ssCpuUser.0'} %</FONT><BR>\n"; 
	push @html, "<FONT COLOR=\"#AA22AA\">System CPU Usage: </FONT>\n"; 
	push @html, "<FONT COLOR=\"#AAAAAA\">"; 
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.systemStats.ssCpuSystem.0'} %</FONT><BR>\n"; 
	push @html, "<FONT COLOR=\"#AA22AA\">CPU Idle: </FONT>\n"; 
	push @html, "<FONT COLOR=\"#AAAAAA\">"; 
	push @html, "$snmp{'ucd'}{'enterprises.ucdavis.systemStats.ssCpuIdle.0'} %</FONT><BR>\n"; 
	push @html, "&nbsp;<BR>\n"; 
	push @html, "&nbsp;<BR>\n";
	
	if (@html) { 
		$self->{html} = "@html";
	}
	if (@miberrors) {
		$self->{status} = '0';
		$self->{message} = "@miberrors";
	}
	else {
		$self->{status} = '1';
	}	
	return;
}

1;
