#  modules/penemo/agent/filecheck.pm 
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
## filecheck class
##
####
####
####

package penemo::agent::filecheck;
use lib '/usr/local/share/penemo/lib/';
use strict;

sub new {
	my ($class, %args) = @_;
	
	my $ref = {
		ip	    => $args{ip},
		mod	    => $args{mod},
		message	    => '',
		status	    => '',
		html	    => '',
		dir_plugin  => $args{dir_plugin},
#		agent_ref   => $args{agent_ref},
	};

	bless $ref, $class;
}


# internal methods.
#
sub _get_dir_plugin { $_[0]->{dir_plugin} }
sub _get_mod { $_[0]->{mod} }
sub _get_ip { $_[0]->{ip} }

# external methods.
#
sub status { $_[0]->{status}; }
sub message { $_[0]->{message}; }
sub html { $_[0]->{html}; }

sub exec {
	my $self = shift;
	#my $dir_plugin = $self->_get_dir_plugin() . "/check";
	#my $mod = $self->_get_mod();
	my $ip = $self->_get_ip();
	my @output = ();
	my $ok_light = penemo::core->html_image('agent', 'ok');
	my $bad_light = penemo::core->html_image('agent', 'bad');
	
	if (-f "/tmp/penemo.test") { 
		$self->{status} = "1"; 
		$self->{html} = "$ok_light <FONT COLOR=\"#11AA11\">the file: /tmp/penemo.test exists.</FONT><BR>\n"; 
	} 
	else { 
		$self->{status} = "0"; 
		$self->{message} = "filecheck: the file /tmp/penemo.test does not exists.\n"; 
		$self->{html} = "$bad_light <FONT COLOR=\"#AAAAAA\">filecheck: the file: /tmp/penemo.test does not exists.</FONT><BR>\n"; 
	}      

	return;
}


1;
