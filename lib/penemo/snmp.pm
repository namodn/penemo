#  modules/penemo/snmp.pm 
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

#########################
#########################
#########################
## snmp class
##
####
####
####

package penemo::snmp;

use lib '/home/nick/devel/penemo/modules/';

use strict;

sub new {
	my ($class, %args) = @_;
	
	my $ref = {
		ip	    => $args{ip},
		mib	    => $args{mib},
		community   => $args{community},
		message	    => '',
		status	    => '',
		html	    => '',
		plugin_dir  => $args{plugin_dir},
		ucd_bin_dir => $args{ucd_bin_dir},
	};

	bless $ref, $class;
}


# functions to retrieve values for internal methods.
#
sub _get_plugin_dir { $_[0]->{plugin_dir} }
sub _get_mib { $_[0]->{mib} }
sub _get_ucd_bin_dir { $_[0]->{ucd_bin_dir} }
sub _get_community { $_[0]->{community} }
sub _get_ip { $_[0]->{ip} }


sub poll {
	my $self = shift;
	my $plugin_dir = $self->_get_plugin_dir() . "/snmp";
	my $mib = $self->_get_mib();
	my $ip = $self->_get_ip();
	my $community = $self->_get_community();
	my $ucd_bin_dir = $self->_get_ucd_bin_dir();
	my $snmpwalk = "$ucd_bin_dir/snmpwalk";
	my @output = ();
	

	unless (-f "$plugin_dir/$mib" . '.mib') {
		penemo::core->notify_die("plugin: $plugin_dir/$mib.mib does not exist.\n");
	}

	if (`$plugin_dir/$mib.mib check`) {
		penemo::core->notify_die("$plugin_dir/$mib.mib is not a valid penemo mib plugin.\n");
	}

	@output = `$plugin_dir/$mib.mib $ip $community $snmpwalk`;

	unless (@output) {
		$self->{status} = 0;
		$self->{message} = "execution of $plugin_dir/$mib.mib failed (nothing returned).\n";
		return;
 	}

	unless ($output[0] =~ '--agentdump') {
		$self->{status} = 0;
		$self->{message} = "@output";
		return;
	}
	
	my $test = '';
	my @agentdump = ();
	my @htmldump = ();
	my @miberrors = ();
	foreach my $line (@output) {
		if ($line =~ '--agentdump') {
			$test = '1';
			next;
		}
		elsif ($line =~ '--htmldump') {
			$test = '2';
			next;
		}
		elsif ($line =~ '--miberrors') {
			$test = '3';
			next;
		}

		if ($test == '1') {
			push @agentdump, $line; 	
		}
		elsif ($test == '2') {
			push @htmldump, $line;
		}
		elsif ($test == '3') {
			push @miberrors, $line;
		}
	}

	unless ((@agentdump) && (@htmldump)) {
		$self->{status} = 0;
		$self->{message} = "internal error in snmp.pm (no information returned)\n";
	}
	elsif (@miberrors) {
		$self->{status} = 0;
		$self->{message} = "@miberrors";
		$self->{walk} = "@agentdump";
		$self->{html} = "@htmldump";
	}
	else {
		$self->{status} = 1;
		$self->{html} = "@htmldump";
		$self->{walk} = "@agentdump";
	}
	return;
}

sub status {
	$_[0]->{status};
}

sub message {
	$_[0]->{message};
}

sub html {
	$_[0]->{html};
}

sub walk {
	$_[0]->{walk};
}

1;
