#  modules/penemo/plugin.pm 
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
## plugin class
##
####
####
####

package penemo::plugin;

use lib '/home/nick/devel/penemo/modules/';

use strict;

sub new {
	my ($class, %args) = @_;
	
	my $ref = {
		ip	    => $args{ip},
		mod	    => $args{mod},
		message	    => '',
		status	    => '',
		html	    => '',
		plugin_dir  => $args{plugin_dir},
	};

	bless $ref, $class;
}


# functions to retrieve values for internal methods.
#
sub _get_plugin_dir { $_[0]->{plugin_dir} }
sub _get_mod { $_[0]->{mod} }
sub _get_ip { $_[0]->{ip} }


sub exec {
	my $self = shift;
	my $plugin_dir = $self->_get_plugin_dir() . "/check";
	my $mod = $self->_get_mod();
	my $ip = $self->_get_ip();
	my @output = ();
	

	# die if file doesnt exist
	unless (-f "$plugin_dir/$mod" . '.mod') {
		penemo::core->notify_die("plugin: $plugin_dir/$mod.mod does not exist.\n");
	}

	# doesnt return proper results
	if (`$plugin_dir/$mod.mod check`) {
		penemo::core->notify_die("$plugin_dir/$mod.mod is not a valid penemo check module plugin.\n");
	}

	# execute check plugin module
	@output = `$plugin_dir/$mod.mod exec`;

	unless (@output) {
		$self->{status} = 0;
		$self->{message} = "execution of $plugin_dir/$mod.mod failed (nothing returned).\n";
		return;
 	}

	my @htmldump = ();
	my $html = 0;
	for (my $c = 0; $c <= $#output; $c++) {
		if ($c == '0') {
			if ($output[$c] =~ '0') {
				$self->{status} = 0;
				$c++;
				$self->{message} = $output[$c];
				next;
			}
			elsif ($output[$c] =~ '1') {
				$self->{status} = 1;
				next;
			}
		}

		if ($output[$c] =~ '--htmldump') {
			$html = '1';
			next;
		}

		if ($html == '1') {
			push @htmldump, $output[$c];
			next;
		}
	}
	$self->{html} = "@htmldump";
	
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

1;
