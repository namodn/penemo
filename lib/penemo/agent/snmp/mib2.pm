#  modules/penemo/agent/snmp/mib2.pm 
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

package penemo::agent::snmp::mib2;
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

	my @walk = `$snmpwalk $ip $community mib-2`;

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
		$snmp{'mib2'}{$obj} = $value; 
	} 

	my @miberrors = ();      # stack of errors in snmp mib
	my @html = ();	         # html output
	my @html_chunk = ();	 # chunks of html output
	my $ok_light = penemo::core->html_image('agent', 'ok');
	my $bad_light = penemo::core->html_image('agent', 'bad');
	# print html data


	#
	# System
	#

	push @html, "<FONT COLOR=\"#AA22AA\">System Name: </FONT>";
	push @html, "<FONT COLOR=\"#AAAAAA\">$snmp{'mib2'}{'system.sysName.0'}</FONT><BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">System Description: </FONT>";
	push @html, "<FONT COLOR=\"#AAAAAA\">$snmp{'mib2'}{'system.sysDescr.0'}</FONT><BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">System Contact: </FONT>";
	push @html, "<FONT COLOR=\"#AAAAAA\">$snmp{'mib2'}{'system.sysContact.0'}</FONT><BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">System UpTime (snmpd): </FONT>";
	push @html, "<FONT COLOR=\"#AAAAAA\">$snmp{'mib2'}{'system.sysUpTime.0'}</FONT><BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">System Location: </FONT>";
	push @html, "<FONT COLOR=\"#AAAAAA\">$snmp{'mib2'}{'system.sysLocation.0'}</FONT><BR>\n";
	push @html, "<FONT COLOR=\"#AA22AA\">System ObjectID: </FONT>";
	push @html, "<FONT COLOR=\"#AAAAAA\">$snmp{'mib2'}{'system.sysObjectID.0'}</FONT><BR>\n";
	push @html, "&nbsp;<BR>\n";
	push @html, "&nbsp;<BR>\n";
	    

	#
	# Interfaces
	#

	my $ifnum = $snmp{'mib2'}{'interfaces.ifNumber.0'};
	push @html, "<FONT COLOR=\"#BBBB66\">Number of Interfaces: </FONT>";
	push @html, "<FONT COLOR=\"#AAAAAA\">$ifnum</FONT><BR>\n";
	push @html, "&nbsp;<BR>\n";
  
	for (my $c = '1'; $c <= $ifnum; $c++) { 
		push @html, "<FONT COLOR=\"#AA22AA\">Interface: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">$c</FONT><BR>\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Description: </FONT>\n";
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'mib2'}{'interfaces.ifTable.ifEntry.ifDescr.' . $c}</FONT><BR>\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Type: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'mib2'}{'interfaces.ifTable.ifEntry.ifType.' . $c}</FONT><BR>\n"; 
		push @html, "<FONT COLOR=\"#AA22AA\">Administrative Status: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'mib2'}{'interfaces.ifTable.ifEntry.ifAdminStatus.' . $c}</FONT><BR>\n"; 
	
		if ($snmp{'mib2'}{'interfaces.ifTable.ifEntry.ifOperStatus.' . $c} eq 'up(1)') { 
			if ($snmp{'mib2'}{'interfaces.ifTable.ifEntry.ifAdminStatus.' . $c} eq 'up(1)') { 
				push @html, "$ok_light\n"; 
			} 
			else { 
				push @html, "$bad_light\n";
				my $if = $snmp{'mib2'}{'interfaces.ifTable.ifEntry.ifDescr.' . $c}; 
				push @miberrors, "$if is up, and it apparently shouldnt be on IP: $ip\n"; 
			} 
		} 
		else { 
			if ($snmp{'mib2'}{'interfaces.ifTable.ifEntry.ifAdminStatus.' . $c} eq 'up(1)') { 
				push @html, "$bad_light\n"; 
				my $if = $snmp{'mib2'}{'interfaces.ifTable.ifEntry.ifDescr.' . $c}; 
				push @miberrors, "$if is down, and it's not suppost to be on IP: $ip\n"; 
			} 
		} 
		
		push @html, "<FONT COLOR=\"#AA22AA\">Operational Status: </FONT>\n"; 
		push @html, "<FONT COLOR=\"#AAAAAA\">"; 
		push @html, "$snmp{'mib2'}{'interfaces.ifTable.ifEntry.ifOperStatus.' . $c}</FONT><BR>\n"; 
		# "<FONT COLOR=\"#4422CC\">In Errors: </FONT>\n"; 
		# "$snmp{'mib2'}{'interfaces.ifTable.ifEntry.ifInErrors.' . $c}<BR>\n"; 
		# "<FONT COLOR=\"#4422CC\">Out Errors: </FONT>\n"; 
		# "$snmp{'mib2'}{'interfaces.ifTable.ifEntry.ifOutErrors.' . $c}<BR>\n"; 
		push @html, "&nbsp;<BR>\n"; 
		push @html, "&nbsp;<BR>\n";
	}

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
