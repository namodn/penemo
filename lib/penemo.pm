#  lib/penemo.pm
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
#  penemo homepage : http://www.penemo.org
#
#


############################
############################
## core utilities
####
####

package penemo::core;

use strict;

sub file_write
{
	my ($class, $file, @data) = @_; 
	return unless (@data); 

	open(DATA, "$file") 
		or penemo::core->notify_die("Can't open $file : $!\n"); 
	foreach my $line (@data) 
	{ 
		print DATA $line; 
	} 
	close DATA; 
}


# this function takes one arguments, color, and prints the corresponding
# colored * with HTML tags.
#
sub html_image { 
	my ($class, $file, $name) = @_; 
	my $path = '';
	
	if ($file eq 'index') {
		$path = 'images/';
	}
	elsif ($file eq 'agent') {
		$path = '../../images/';
	}

	if ($name eq 'ok') { 
		return ("<IMG SRC=\"$path/green_button.jpg\" BORDER=0 ALT=\"green\">");
	} 
	elsif ($name eq 'bad') { 
		return ("<IMG SRC=\"$path/red_button.jpg\" BORDER=0 ALT=\"red\">");
	} 
	elsif ($name eq 'pause') { 
		return ("<IMG SRC=\"$path/blue_button.jpg\" BORDER=0 ALT=\"blue\">");
	} 
	elsif ($name eq 'warn') {
		return ("<IMG SRC=\"$path/yellow_button.jpg\" BORDER=0 ALT=\"yellow\">");
	}
	else {
		return ("* "); 
	} 
}

# sends a notification message and dies. requires no class. 
# only param is error msg string. only supports email because 
# it should only be used when there is an internal
# penemo error. an unrecoverable problem, not a agent check failure. 
# sends email to root@localhost
#
sub notify_die {
	my ($class, $msg) = @_;

	print "\n\n** penemo had an internal error:\n";
	print "**   $msg\n";
	print "** sending emergency notification to root\@localhost\n";

	open(MAIL, "| /usr/sbin/sendmail -t -oi") 
			or die "Can't send death notification email : $!\n"; 
		print MAIL "To: root\@localhost\n"; 
		print MAIL "From: penemo-notify\n";
		print MAIL "Subject: penemo died!\n"; 
		print MAIL "  The following error was encountered\n"; 
		print MAIL "The error had _fatal_ results, please fix asap.\n";
		print MAIL "\n"; 
		print MAIL $msg; 
		print MAIL "\n"; 
	close MAIL; 

	print "** dying...\n";
	die;
}


#############################
#############################
## the config class
####
####

package penemo::config;

use lib '/usr/local/share/penemo/modules';
use strict;
use penemo;
use penemo::agent;

sub load_config
{
	my ($class, $penemo_conf, $agent_conf) = @_;

	my ($global_conf_ref, $agent_defaults_ref) = &_default_config($penemo_conf);
	my %global_conf = %$global_conf_ref;
	my %agent_defaults = %$agent_defaults_ref;

	my $agent_ref = &_agent_config($agent_conf, %agent_defaults);
	my %agents = %$agent_ref;

	my %conf = (%global_conf, %agents);

	my $ref = \%conf;
	bless $ref, $class;
}

sub _default_config
{
	my ($conf_file) = @_;
	my $key = '';
	my $value = '';
	my %conf = ( 
		notify_method_1 => 'email',
		notify_method_2 => 'email',
		notify_method_3 => 'email',
		notify_level    => '1',
		notify_cap	=> '0',
		notify_email_1  => 'root@localhost',
		notify_email_2  => 'root@localhost',
		notify_email_3  => 'root@localhost',
		notify_exec_1	=> '',
		notify_exec_2	=> '',
		notify_exec_3	=> '',
		notify_errlev_reset	=> '1',
		http_command    => 'wget',
		snmp_community  => 'public',
		ping_timeout    => '1',
		dir_html        => '/usr/local/share/penemo/html',
		dir_cache       => '/usr/local/share/penemo/cache',
		dir_data	=> '/usr/local/share/penemo/data',
		dir_ucd_bin     => '/usr/local/bin',
		dir_plugin	=> '/usr/local/share/penemo/plugins',
		dir_log		=> '/usr/local/share/penemo/logs',
		dir_cgibin	=> '/cgi-bin',
		tier_support	=> '0',
		tier_promote	=> '3',
		instance_name	=> 'default instance',
		penemo_bin      => '/usr/local/sbin/penemo',
		pause_box_index => '0',
		pause_web       => '1',
		pause_global    => '0',
	);
	open(CFG, "$conf_file")
	            or penemo::core->notify_die("Can't open $conf_file : $!\n");

	while (<CFG>) { 
		next if ($_ =~ /^\s*#/); 
		next if ($_ =~ /^\s*$/); 
		chomp; 
		if ($_ =~ /^notify_exec/) { 
			($key, $value) = split(/_command\s*/, $_); 
			$conf{'notify_exec'} = $value; 
			next; 
		} 
		elsif ($_ =~ /^instance_name/) { 
			($key, $value) = split(/_name\s*/, $_); 
			$conf{'instance_name'} = $value; 
			next; 
		} 
		($key, $value) = split(/\s+/, $_); 
		$conf{$key} = $value; 
	} 
	close CFG;

	my %agent = (
		notify_method_1	=> $conf{notify_method_1},
   		notify_method_2	=> $conf{notify_method_2},
   		notify_method_3	=> $conf{notify_method_3},
   		notify_level 	=> $conf{notify_level},
   		notify_cap 	=> $conf{notify_cap},
   		notify_email_1 	=> $conf{notify_email_1},
   		notify_email_2 	=> $conf{notify_email_2},
   		notify_email_3 	=> $conf{notify_email_3},
		notify_exec_1   => $conf{notify_exec},
		notify_exec_2   => $conf{notify_exec},
		notify_exec_3   => $conf{notify_exec},
		snmp_community  => $conf{snmp_community},
		ping_timeout    => $conf{ping_timeout},
		id_name		=> 'undefined',
		id_group	=> 'undefined',
		notify_errlev_reset	=> $conf{notify_errlev_reset},
		notification_stack	=> '',
		notification_org	=> [],
		tier_support	=> $conf{tier_support},
		tier_promote	=> $conf{tier_promote},
	);

	my %global = ( default	=> {
			penemo_bin      => $conf{penemo_bin},
			instance_name	=> $conf{instance_name}, 
			dir_html        => $conf{dir_html},
			dir_cache       => $conf{dir_cache},
			dir_data	=> $conf{dir_data},
			dir_plugin	=> $conf{dir_plugin},
			dir_log		=> $conf{dir_log},
			dir_cgibin	=> $conf{dir_cgibin},
			dir_ucd_bin	=> $conf{dir_ucd_bin},
			http_command    => $conf{http_command},
			pause_web       => $conf{pause_web},
			pause_box_index => $conf{pause_box_index},
			pause_global    => $conf{pause_global},
		},
	);
   
	return (\%global, \%agent);
}

sub _agent_config {
        my ($conf_file, %agent_defaults) = @_;
        my %conf = ();
        my $line_num = 0;
       	my $ip = '';
       	my $begin = 0;
   
        open(CFG, "$conf_file")
                or penemo::core->notify_die("Can't open $conf_file : $!\n");
        while (<CFG>) {
		chomp;
		my $line = $_;
                $line_num++;
                $line =~ s/\s*#.*$//;
                next if ($line =~ /^\s*$/);
                next unless ($line =~ /^\w*/);

		unless ($ip) {
			next if ($begin); 
			my $else = '';
			($ip, $else) = split(/ /, $line); 
			unless ($ip)	{ $ip = $line; }
			next unless ($else); 
			$line = $else;
                }

                if ($line =~ /^{/) {
                        if ($ip) {
                                $begin = '1';
                                $conf{agent_list} ||= '';
                                $conf{agent_list} .= "$ip ";
				$conf{$ip} = { %agent_defaults };
                        }
                        else {
                                penemo::core->notify_die("penemo: syntax error in agent.conf line $line_num\n");
                        }
			next;
                }

                if ($line =~ /^}\s*/) {
			undef $ip;
                        $begin = 0;
			next;
                }

		if ($line =~ /^\s*PING\s*/i) {
			$conf{$ip}{ping_check} = "1";
			&_agent_params(\%conf, $ip, 'ping', $line);
		}
		elsif ($line =~ /^\s*HTTP\s{1}/i) {
			&_agent_params(\%conf, $ip, 'http', $line);
			if ($conf{$ip}{http_url}) {
				$conf{$ip}{http_check} = '1';
			}
		}
		elsif ($line =~ /^\s*SNMP\s{1}/i) {
			&_agent_params(\%conf, $ip, 'snmp', $line);
			if ($conf{$ip}{snmp_mibs}) {
				$conf{$ip}{snmp_check} = '1';
			}
		}
		elsif ($line =~ /^\s*ID\s{1}/i) {
			&_agent_params(\%conf, $ip, 'id', $line);
		}
		elsif ($line =~ /^\s*NOTIFY\s{1}/i) {
			&_agent_params(\%conf, $ip, 'notify', $line);
		}
		elsif ($line =~ /^\s*PLUGIN\s{1}/i) {
			my $plugin_conf = $line;
			$plugin_conf =~ s/mods=\".*?\"//;
			&_agent_params(\%conf, $ip, 'plugin', $line);
			&_agent_params_plugin(\%conf, $ip, 'plugin_conf', $plugin_conf);
	
			if ($conf{$ip}{plugin_mods}) {
				$conf{$ip}{plugin_check} = '1';
			}
		
		}
		elsif ($line =~ /^\s*TIER\s{1}/i) {
			&_agent_params(\%conf, $ip, 'tier', $line);
		}
	}
	close CFG;

        return \%conf;
}

sub _agent_params {
        my ($conf_ref, $ip, $func, $line) = @_;
        $line =~ s/^\s*$func\s*//img;
        return unless ($line);
        my @tmp = split(/"\s*/, $line);
        while (@tmp) {
                my $param = shift @tmp;
                $param =~ s/=//mg;
                $param =~ tr/A-Z/a-z/;
                my $value = shift @tmp;
		my $func = $func . '_' . $param;
                $conf_ref->{$ip}{$func} = $value;
        }
}

# plugin specific assignments
sub _agent_params_plugin {
        my ($conf_ref, $ip, $func, $line) = @_;
        $line =~ s/^\s*plugin\s*//img;
        return unless ($line);
        my @tmp = split(/"\s*/, $line);
        while (@tmp) {
                my $param = shift @tmp;
                $param =~ s/=//mg;
                $param =~ tr/A-Z/a-z/;
                my $value = shift @tmp;
                $conf_ref->{$ip}{$func}{$param} = $value;
        }
}

# methods for load_config object. (global conf settings).
sub get_dir_html                { $_[0]->{default}{dir_html} }
sub get_dir_cache               { $_[0]->{default}{dir_cache} }
sub get_dir_data		{ $_[0]->{default}{dir_data} }
sub get_dir_plugin		{ $_[0]->{default}{dir_plugin} }
sub get_dir_log			{ $_[0]->{default}{dir_log} }
sub get_dir_cgibin		{ $_[0]->{default}{dir_cgibin} }
sub get_penemo_bin              { $_[0]->{default}{penemo_bin} }
sub get_dir_ucd_bin             { $_[0]->{default}{dir_ucd_bin} }
sub get_http_command            { $_[0]->{default}{http_command} }
sub get_instance_name		{ $_[0]->{default}{instance_name} }
sub get_pause_web		{ $_[0]->{default}{pause_web} }
sub get_pause_box_index		{ $_[0]->{default}{pause_box_index} }
sub get_pause_global		{ $_[0]->{default}{pause_global} }

sub _next_ip {
	my @ip_list = split (/ /, $_[0]->{agent_list});
	my $ip = shift @ip_list;
	$_[0]->{agent_list} = join ' ', @ip_list;
	return $ip;
}
sub _name {
	my ($self, $ip) = @_;
	$self->{$ip}{id_name};
}
sub _group {
	my ($self, $ip) = @_;
	$self->{$ip}{id_group};
}

sub _notify_method_1 { 
	my ($self, $ip) = @_;
	$self->{$ip}{notify_method_1}; 
}
sub _notify_method_2 { 
	my ($self, $ip) = @_;
	$self->{$ip}{notify_method_2}; 
}
sub _notify_method_3 { 
	my ($self, $ip) = @_;
	$self->{$ip}{notify_method_3}; 
}

sub _notify_level { 
	my ($self, $ip) = @_;
	$self->{$ip}{notify_level}; 
}
sub _notify_cap { 
	my ($self, $ip) = @_;
	$self->{$ip}{notify_cap}; 
}

sub _notify_email_1 { 
	my ($self, $ip) = @_;
	$self->{$ip}{notify_email_1}; 
}
sub _notify_email_2 { 
	my ($self, $ip) = @_;
	$self->{$ip}{notify_email_2}; 
}
sub _notify_email_3 { 
	my ($self, $ip) = @_;
	$self->{$ip}{notify_email_3}; 
}

sub _notify_exec_1 { 
	my ($self, $ip) = @_;
	$self->{ip}{notify_exec_1}; 
}
sub _notify_exec_2 { 
	my ($self, $ip) = @_;
	$self->{ip}{notify_exec_2}; 
}
sub _notify_exec_3 { 
	my ($self, $ip) = @_;
	$self->{ip}{notify_exec_3}; 
}

sub _ping_timeout {
	my ($self, $ip) = @_;
        $self->{$ip}{ping_timeout};
}
sub _http_url {
	my ($self, $ip) = @_;
        $self->{$ip}{http_url};
}
sub _http_search {
	my ($self, $ip) = @_;
        $self->{$ip}{http_search};
}
sub _snmp_mibs {
	my ($self, $ip) = @_;
        $self->{$ip}{snmp_mibs};
}
sub _snmp_community { 
	my ($self, $ip) = @_;
	$self->{$ip}{snmp_community}; 
}
sub _plugin_mods {
	my ($self, $ip) = @_;
	$self->{$ip}{plugin_mods};
}

sub _plugin_conf {
	my ($self, $ip) = @_;
	if ($self->{$ip}{plugin_conf}->{filecheck_test}) {
		#print "BUG? $ip: ", $self->{$ip}{plugin_conf}->{filecheck_test}, ".\n";
	}

	return %{$self->{$ip}{plugin_conf}};
}

sub _notify_errlev_reset {
	my ($self, $ip) = @_;
	$self->{$ip}{notify_errlev_reset};
}
sub _tier_support { 
	my ($self, $ip) = @_;
	$self->{$ip}{tier_support} 
}
sub _tier_promote { 
	my ($self, $ip) = @_;
	$self->{$ip}{tier_promote} 
}


#
# returns true if function is to be performed for the specified agent.
#
sub _ping_check {
        my ($self, $ip) = @_;
        $self->{$ip}{ping_check};
}
sub _http_check {
        my ($self, $ip) = @_;
        $self->{$ip}{http_check};
}
sub _snmp_check {
        my ($self, $ip) = @_;
        $self->{$ip}{snmp_check};
}
sub _plugin_check {
	my ($self, $ip) = @_;
	$self->{$ip}{plugin_check};
}



#
# get the info for the next agent in list, and send it to penemo::agent 
# to return an objref.
#
sub get_next_agent {
        my $self = shift;
	my $ip = $self->_next_ip();
	unless ($ip)	{ return undef; }

	return penemo::agent::->new( 
					ip              => $ip, 
					name		=> $self->_name($ip),
	
					ping_check	=> $self->_ping_check($ip),
					ping_timeout    => $self->_ping_timeout($ip), 
					http_check	=> $self->_http_check($ip),
					http_url        => $self->_http_url($ip), 
					http_search     => $self->_http_search($ip), 
					snmp_check	=> $self->_snmp_check($ip),
					snmp_community  => $self->_snmp_community($ip),
					snmp_mibs	=> $self->_snmp_mibs($ip), 
					plugin_check	=> $self->_plugin_check($ip),
					plugin_mods	=> $self->_plugin_mods($ip),
					plugin_conf	=> { $self->_plugin_conf($ip) },
					group		=> $self->_group($ip),
					notify_method_1	=> $self->_notify_method_1($ip),
					notify_method_2	=> $self->_notify_method_2($ip),
					notify_method_3	=> $self->_notify_method_3($ip),
					notify_level	=> $self->_notify_level($ip),
					notify_cap	=> $self->_notify_cap($ip),
					notify_email_1	=> $self->_notify_email_1($ip),
					notify_email_2	=> $self->_notify_email_2($ip),
					notify_email_3	=> $self->_notify_email_3($ip),
					notify_exec_1	=> $self->_notify_exec_1($ip),
					notify_exec_2	=> $self->_notify_exec_2($ip),
					notify_exec_3	=> $self->_notify_exec_3($ip),
					tier_support	=> $self->_tier_support($ip),
					tier_promote	=> $self->_tier_promote($ip),
					notify_errlev_reset	=> $self->_notify_errlev_reset($ip),
					current_tier	=> '1',
	);
}


##
##
## below stuff should be in sperate class
##
##

## functions for creating notify class objects
sub push_notification_stack {
	my ($self, $objref) = ($_[0], $_[1]);
	push @{ $self->{notification_stack} }, $objref;
}

sub _shift_notification_stack 	{ return shift @{ $_[0]->{notification_stack} }; }

# organize notification objects by email to send, or exec
sub organize_notification_info {
	my $self = shift;

	while () {
		last unless ( my $agent = $self->_shift_notification_stack() );
		my $ip = $agent->get_ip();

		my $method = '';
		my $email = '';
		my $exec = '';


		unless ($agent->get_tier_support()) {
			$method = $agent->get_notify_method_1();
			if ($method eq 'email') {
				$email = $agent->get_notify_email_1();
			}
			elsif ($method eq 'exec') {
				$exec = $agent->get_notify_exec_1();
			}
		}
		else {
			if ($agent->get_notifications_sent() >= $agent->get_tier_promote()) {
				unless ($agent->get_current_tier() == '3') {
					$agent->set_current_tier('+') unless ($agent->get_error_resolved());
					$agent->set_notifications_sent('0');
				}
			}

			if ($agent->get_current_tier() == '1') {
				$method = $agent->get_notify_method_1();
				if ($method eq 'email') {
					$email = $agent->get_notify_email_1();
				}
				elsif ($method eq 'exec') {
					$exec = $agent->get_notify_exec_1();
				}
			}
			if ($agent->get_current_tier() == '2') {
				$method = $agent->get_notify_method_2();
				if ($method eq 'email') {
					$email = $agent->get_notify_email_2();
				}
				elsif ($method eq 'exec') {
					$exec = $agent->get_notify_exec_2();
				}
			}
			if ($agent->get_current_tier() == '3') {
				$method = $agent->get_notify_method_3();
				if ($method eq 'email') {
					$email = $agent->get_notify_email_3();
				}
				elsif ($method eq 'exec') {
					$exec = $agent->get_notify_exec_3();
				}
			}
		}
		

		# do a different heirarchal organization depending on if the
		# notification method is exec or email.
		unless ($method eq 'exec') {
			$self->{notification_org}{$email}{$ip}{ping_check} = 
					$agent->ping_check(); 
			$self->{notification_org}{$email}{$ip}{http_check} = 
					$agent->http_check();
			$self->{notification_org}{$email}{$ip}{snmp_check} = 
					$agent->snmp_check();
			$self->{notification_org}{$email}{$ip}{plugin_check} = 
					$agent->plugin_check();
			$self->{notification_org}{$email}{$ip}{ping_status} = 
					$agent->get_ping_status(); 
			$self->{notification_org}{$email}{$ip}{http_status} = 
					$agent->get_http_status(); 
			$self->{notification_org}{$email}{$ip}{http_get_status} = 
					$agent->get_http_get_status(); 
			$self->{notification_org}{$email}{$ip}{http_search_status} = 
					$agent->get_http_search_status(); 
			
			if ($agent->get_snmp_mibs()) {
				$self->{notification_org}{$email}{$ip}{mib_list} =
						$agent->get_snmp_mibs();
				my @mibs = split(/ /, $agent->get_snmp_mibs());
				foreach my $mib (@mibs) {
					$self->{notification_org}{$email}{$ip}{snmp_status} = 
							$agent->get_snmp_status($mib); 
					$self->{notification_org}{$email}{$ip}{snmp_msg} = 
							$agent->get_snmp_message($mib);
				}
			}
			else {
				$self->{notification_org}{$email}{$ip}{snmp_status} = ''; 
				$self->{notification_org}{$email}{$ip}{snmp_msg} = '';
			}

			if ($agent->get_plugin_mods()) {
				$self->{notification_org}{$email}{$ip}{mib_list} =
						$agent->get_plugin_mods();
				my @mods = split(/ /, $agent->get_plugin_mods());
				foreach my $mod (@mods) {
					$self->{notification_org}{$email}{$ip}{plugin_status} = 
							$agent->get_plugin_status($mod); 
					$self->{notification_org}{$email}{$ip}{plugin_msg} = 
							$agent->get_plugin_message($mod);
				}
			}
			else {
				$self->{notification_org}{$email}{$ip}{plugin_status} = ''; 
				$self->{notification_org}{$email}{$ip}{plugin_msg} = '';
			}
			
			
			$self->{notification_org}{$email}{$ip}{ping_msg} = 
					$agent->get_ping_message(); 
			$self->{notification_org}{$email}{$ip}{http_get_msg} =
					$agent->get_http_get_message();
			$self->{notification_org}{$email}{$ip}{http_search_msg} =
					$agent->get_http_search_message();
			$self->{notification_org}{$email}{$ip}{name} = $agent->get_name();

			# global setting for each notification message (object)
			$self->{notification_org}{$email}{current_tier} = $agent->get_current_tier();
		}
		else {
			$self->{notification_org}{notify}{$ip}{exec} = $exec;
			$self->{notification_org}{notify}{$ip}{ping_check} = 
					$agent->ping_check(); 
			$self->{notification_org}{notify}{$ip}{http_check} = 
					$agent->http_check();
			$self->{notification_org}{notify}{$ip}{snmp_check} = 
					$agent->snmp_check();
			$self->{notification_org}{notify}{$ip}{plugin_check} = 
					$agent->plugin_check();
			$self->{notification_org}{notify}{$ip}{ping_status} = 
					$agent->get_ping_status(); 
			$self->{notification_org}{notify}{$ip}{http_status} = 
					$agent->get_http_status(); 
			$self->{notification_org}{notify}{$ip}{http_get_status} = 
					$agent->get_http_get_status(); 
			$self->{notification_org}{notify}{$ip}{http_search_status} = 
					$agent->get_http_search_status(); 
			
			if ($agent->get_snmp_mibs()) {
				$self->{notification_org}{notify}{$ip}{mib_list} =
						$agent->get_snmp_mibs();
				my @mibs = split(/ /, $agent->get_snmp_mibs());
				foreach my $mib (@mibs) {
					$self->{notification_org}{notify}{$ip}{snmp_status} = 
							$agent->get_snmp_status($mib); 
					$self->{notification_org}{notify}{$ip}{snmp_msg} = 
							$agent->get_snmp_message($mib);
				}
			}
			else {
				$self->{notification_org}{notify}{$ip}{snmp_status} = ''; 
				$self->{notification_org}{notify}{$ip}{snmp_msg} = '';
			}

			if ($agent->get_plugin_mods()) {
				$self->{notification_org}{notify}{$ip}{mib_list} =
						$agent->get_plugin_mods();
				my @mods = split(/ /, $agent->get_plugin_mods());
				foreach my $mod (@mods) {
					$self->{notification_org}{notify}{$ip}{plugin_status} = 
							$agent->get_plugin_status($mod); 
					$self->{notification_org}{notify}{$ip}{plugin_msg} = 
							$agent->get_plugin_message($mod);
				}
			}
			else {
				$self->{notification_org}{notify}{$ip}{plugin_status} = ''; 
				$self->{notification_org}{notify}{$ip}{plugin_msg} = '';
			}
			
			
			$self->{notification_org}{notify}{$ip}{ping_msg} = 
					$agent->get_ping_message(); 
			$self->{notification_org}{notify}{$ip}{http_get_msg} =
					$agent->get_http_get_message();
			$self->{notification_org}{notify}{$ip}{http_search_msg} =
					$agent->get_http_search_message();
			$self->{notification_org}{notify}{$ip}{name} = $agent->get_name();

			# global setting for each notification message (object)
			$self->{notification_org}{notify}{current_tier} = $agent->get_current_tier();
		}

		if ($agent->get_error_resolved()) {
			print "$ip, resolved problem\n";
			$self->{notification_org}{$email}{$ip}{resolved} = '1';
			$agent->set_notifications_sent('0');
			$agent->set_current_tier('1');
		}
		else {
			$self->{notification_org}{$email}{$ip}{resolved} = '0';
			$agent->set_have_notifications_been_sent('1');
			$agent->set_notifications_sent('+');
		}

		
	}
}

sub get_notification_object_array {
	my $self = shift;
	my @new_objects = ();
	foreach my $method (keys %{ $self->{notification_org} }) {
		my $obj = penemo::notify->new( 
					_method => $method,
					%{ $self->{notification_org}{$method} },
		);

		push @new_objects, $obj;
	}

	return @new_objects;
}
	

# functions for stacking ip for index_html_write 
#
sub push_html_agentlist { 
	my ($self, $objref) = @_; 
	push @{ $self->{html_agentlist} }, $objref; 
} 

sub _get_html_agentlist { 
	return @{ $_[0]->{html_agentlist} }; 
} 

# write the index.html that lists all the agents and a general status indicator
sub index_html_write {
	my ($self, $version, $date) = @_;
	my @agentlist = $self->_get_html_agentlist();
	my @grouplist = ();
	my $index = $self->get_dir_html() . "/index.html";
	my $line = '';
	my $ok_light = penemo::core->html_image('index', 'ok'); 
	my $bad_light = penemo::core->html_image('index', 'bad'); 
	my $paused_light = penemo::core->html_image('index', 'pause'); 
	my $warn_light = penemo::core->html_image('index', 'warn'); 
	my $max_ip_length = 0;
	my $cgi_bin = $self->get_dir_cgibin();

	foreach my $ref (@agentlist) {
		my $group = $ref->get_group();
		my $grouplist_search = join('"', @grouplist);
		$grouplist_search = '"' . $grouplist_search . '"';
		unless ($grouplist_search =~ /\"$group\"/) {
			push @grouplist, $group;
		}

		my $ip = $ref->get_ip();
		my $length = length($ip);
		$max_ip_length = $length	if ($length > $max_ip_length);
	}

	open(HTML, ">$index") or penemo::core->notify_die("Can't write to $index : $!\n"); 
		print HTML "<HTML>\n"; 
		print HTML "<HEAD>\n"; 
		print HTML "<META HTTP-EQUIV=\"refresh\" CONTENT=\"120\; URL=index.html\">\n";
		print HTML "\t<TITLE>penemo -- Perl Network Monitor</TITLE>\n"; 
		print HTML "</HEAD>\n"; 
		print HTML "<BODY BGCOLOR=\"#000000\" TEXT=\"#338877\" "; 
		print HTML "LINK=\"#AAAAAA\" VLINK=\"#AAAAAA\">\n"; 
		print HTML "<CENTER>\n"; 
		print HTML "<FONT SIZE=3><B>", $self->get_instance_name(), "</B></FONT><BR>\n";
		print HTML "\t<FONT SIZE=2><B><FONT COLOR=\"#CC11AA\">penemo</FONT> "; 
		print HTML "version $version</B></FONT><BR>\n"; 
		#print HTML "<HR WIDTH=60%>\n"; 
		print HTML "<FONT SIZE=2>penemo last run: <FONT COLOR=\"#AAAAAA\">$date</FONT></FONT><BR>\n"; 
		print HTML "</CENTER>\n"; 

		print HTML "<FORM method=\"Post\" action=\"$cgi_bin/penemo-admin.cgi\">\n";
		print HTML "<TABLE WITH=600 ALIGN=CENTER BORDER=0>\n";

		if (($self->get_pause_global()) && ($self->get_pause_web())) {
			my $iplist = '';
			my $tog = 0;
			foreach my $agent (@agentlist) {
				my $ip = $agent->get_ip();
				if ($agent->get_paused()) { $tog = 1; }
				$iplist ||= ''; 
				$iplist .= "$ip|";
			}
			
			print HTML "<TR><TD WIDTH=600 ALIGN=CENTER COLSPAN=4>\n";
			print HTML "&nbsp;<BR>\n";

			print HTML "<FONT COLOR=#3366FF SIZE=2>";
			print HTML "[<A HREF=\"$cgi_bin/penemo-admin.cgi?agent=", $iplist, "&pause=1\">";
			print HTML "<FONT COLOR=#4455FF SIZE=2>global pause</FONT></A>]</FONT>\n"; 

			if ($tog) {
				print HTML "<FONT COLOR=#3366FF SIZE=2>";
				print HTML "[<A HREF=\"$cgi_bin/penemo-admin.cgi?agent=", $iplist, "&unpause=1\">";
				print HTML "<FONT COLOR=#4455FF SIZE=2>global unpause</FONT></A>]</FONT>\n"; 
			}
			print HTML "<BR>\n";

			print HTML "</TD></TR>\n";
		}
			
		foreach my $group (@grouplist) { 
			print HTML "<TR><TD WIDTH=600 ALIGN=LEFT COLSPAN=4>\n";
			print HTML "<BR><FONT SIZE=3><B>$group</B><BR>\n"; 
			print HTML "</TD></TR>\n";
			foreach my $agent (@agentlist) { 
				my $ip = $agent->get_ip();
				if ($agent->get_group() eq "$group") { 
					print HTML "<TR><TD WIDTH=150 ALIGN=LEFT>\n";
					print HTML "<FONT SIZE=3 COLOR=\"#AAAAAA\">\n"; 
					if ($agent->get_paused()) {
						print HTML "$paused_light  ";
					}
					elsif ($agent->get_index_error_detected()) { 
						if ($agent->get_on_notify_stack()) {
							print HTML "$bad_light\n";
						}
						else {
							print HTML "$warn_light\n";
						}
					} 
					else { 
						print HTML "$ok_light  ";
					} 
					print HTML "<FONT SIZE=2>\n";
					print HTML "<A HREF=\"agents/$ip/index.html\">$ip</A><BR>\n";
					print HTML "</FONT>\n";
					print HTML "</TD>\n";
					print HTML "<TD WIDTH=200 ALIGN=LEFT>\n";
					print HTML "<FONT SIZE=2 COLOR=#CCDDA><B>\n";
					print HTML $agent->get_name();
					print HTML "</B></FONT></FONT>\n"; 
					print HTML "</TD>\n";
					print HTML "<TD WIDTH=200 ALIGN=LEFT>\n";
					print HTML "<FONT SIZE=1 COLOR=#AAAADD>";
					if ($agent->ping_check()) { print HTML " ping"; }
					if ($agent->http_check()) { print HTML ", http"; }
					if ($agent->snmp_check()) { 
						print HTML ", snmp: "; 
						print HTML $agent->get_snmp_mibs();
					}
					if ($agent->plugin_check()) { 
						print HTML ", plugin: "; 
						print HTML $agent->get_plugin_mods();
					}
					print HTML "</FONT><BR>\n";

					print HTML "</TD>\n";
					print HTML "<TD WIDTH=50 ALIGN=LEFT>\n";
					if (($agent->get_paused()) && ($self->get_pause_web())) {
						print HTML "<FONT COLOR=#AAAADD SIZE=1><I>untill: ",
							$agent->get_paused_end(), "</I></FONT><BR>\n";
						print HTML "<FONT COLOR=#3366FF SIZE=1>";
						print HTML "[<A HREF=\"$cgi_bin/penemo-admin.cgi?agent=$ip&unpause=1\">";
						print HTML "<FONT COLOR=#4455FF SIZE=1>unpause</FONT></A>]</FONT><BR>\n"; 
					}
					elsif ($self->get_pause_web()) {
						print HTML "<FONT COLOR=#3366FF SIZE=1>";
						print HTML "[<A HREF=\"$cgi_bin/penemo-admin.cgi?agent=$ip&pause=1\">";
						print HTML "<FONT COLOR=#4455FF SIZE=1>pause</FONT></A>]</FONT><BR>\n"; 
					}
					print HTML "</FONT>\n";
					print HTML "</TD></TR>\n";
				} 
			} 
			#print HTML "<TR><TD WIDTH=600 ALIGN=LEFT COLSPAN=4>\n";
			#print HTML "&nbsp;<BR>\n"; 
			#print HTML "</TD></TR>\n";
		} 

		print HTML "</TABLE>\n";
		print HTML "</FORM>\n";
		print HTML "&nbsp;<BR>\n"; 
		print HTML "<HR WIDTH=50%>\n"; 
		print HTML "<CENTER>\n"; 
		print HTML "\t<FONT SIZE=2><I>Developed by "; 
		print HTML "<A HREF=mailto:nick\@namodn.com>Nick Jennings</A>"; 
		print HTML "</I></FONT></BR>\n"; 
		print HTML "</CENTER>\n"; 
		print HTML "</BODY>\n"; 
		print HTML "</HTML>\n"; 
	close HTML; 
} 


###################
###################
## notify class
####
####

package penemo::notify;

sub new {
	my ($class, %args) = @_;
	
	my $self = bless { %args }, $class;

	return $self;
}

sub get_method {
	$_[0]->{_method};
}
sub _get_iplist {
	my @iplist = ();
	foreach my $key (keys %{$_[0]}) {
		next if ($key eq '_method');
		next if ($key eq 'current_tier');
		push @iplist, $key;
	}
	return (@iplist);
}

# the following type_check and type_msg methods require the IP 
# address as a parameter to the method

# ping
sub _get_ping_check {
	my ($self, $ip) = @_;
	return ($self->{$ip}{ping_check});	
}
sub _get_ping_status {
	my ($self, $ip) = @_;
	return ($self->{$ip}{ping_status});	
}
sub _get_ping_msg {
	my ($self, $ip) = @_;
	return ($self->{$ip}{ping_msg});	
}

# http
sub _get_http_check {
	my ($self, $ip) = @_;
	return ($self->{$ip}{http_check});	
}
sub _get_http_status {
	my ($self, $ip) = @_;
	return ($self->{$ip}{http_status});	
}
sub _get_http_get_status {
	my ($self, $ip) = @_;
	return ($self->{$ip}{http_get_status});	
}
sub _get_http_search_status {
	my ($self, $ip) = @_;
	return ($self->{$ip}{http_search_status});	
}
sub _get_http_get_msg {
	my ($self, $ip) = @_;
	return ($self->{$ip}{http_get_msg});	
}
sub _get_http_search_msg {
	my ($self, $ip) = @_;
	return ($self->{$ip}{http_search_msg});	
}

# snmp
sub _get_snmp_check {
	my ($self, $ip) = @_;
	return ($self->{$ip}{snmp_check});	
}
sub _get_snmp_status {
	my ($self, $ip) = @_;
	return ($self->{$ip}{snmp_status});	
}
sub _get_snmp_msg {
	my ($self, $ip) = @_;
	return ($self->{$ip}{snmp_msg});	
}

# plugin
sub _get_plugin_check {
	my ($self, $ip) = @_;
	return ($self->{$ip}{plugin_check});	
}
sub _get_plugin_status {
	my ($self, $ip) = @_;
	return ($self->{$ip}{plugin_status});	
}
sub _get_plugin_msg {
	my ($self, $ip) = @_;
	return ($self->{$ip}{plugin_msg});	
}

# global per object
sub _get_name {
	my ($self, $ip) = @_;
	return ($self->{$ip}{name});
}

sub _get_resolved { 
	my ($self, $ip) = @_;
	return ($self->{$ip}{resolved});
}
sub _get_current_tier {
	my ($self) = @_;
	return ($self->{current_tier});
}



sub email {
	my ($self, $instance, $version) = @_;
	my @iplist = $self->_get_iplist();
	my @msg = ();

	foreach my $ip (@iplist) {
		my $name = $self->_get_name($ip);
		push @msg, "$ip : $name\n";
		if ($self->_get_resolved($ip)) {
			push @msg, "  all errors resolved.\n";
		}
		else {
			my @tmp = $self->_get_message($ip);
			foreach my $line (@tmp) {
				push @msg, $line;
			}
		}
	}
	my $to = $self->get_method();
		
	chomp @msg;
	
        open(MAIL, "| /usr/sbin/sendmail -t -oi") 
			or penemo::core->notify_die("Can't send notification email : $!\n"); 
		print MAIL "To: $to\n"; 
		print MAIL "From: penemo_notify\n";
		print MAIL "Subject: $instance\n"; 
		print MAIL "\n"; 
		print MAIL "  penemo $version\n"; 
		print MAIL "\n"; 
		foreach my $line (@msg) {
			print MAIL "$line\n"; 
		}
		print MAIL "\n"; 
		print MAIL "tier level: ", $self->_get_current_tier(), "\n";
		print MAIL "tier email: $to\n";
	close MAIL; 

	print "--\n"; 
	foreach my $line (@msg) {
		print "$line\n"; 
	}
	print "\n";
	print "tier level: ", $self->_get_current_tier(), "\n";
	print "tier email: $to\n";
	print "--\n";

}

sub execute {
	print "execute method not implemented.\n";
}


sub _get_message {
	my ($self, $ip) = @_;
	my @msg = ();
	if ( ($self->_get_ping_check($ip)) && (! $self->_get_ping_status($ip)) ) {
		my $msg = $self->_get_ping_msg($ip);
		chomp $msg;
		my $line = "  ping: $msg\n";
		push @msg, $line;
	}
	if ($self->_get_http_check($ip)) {
		unless ($self->_get_http_get_status($ip)) {
			my $msg = $self->_get_http_get_msg($ip);
			chomp $msg;
			my $line = "  http: $msg\n";
			push @msg, $line;
		}
		elsif ( (! $self->_get_http_search_status($ip)) && 
				($self->_get_http_search_msg($ip)) ) {
			my $msg = $self->_get_http_search_msg($ip);
			chomp $msg;
			my $line = "  http: $msg\n";
			push @msg, $line;
		}
	}
	if ( ($self->_get_snmp_check($ip)) && (! $self->_get_snmp_status($ip)) ) {
		my $msg = $self->_get_snmp_msg($ip);
		chomp $msg;
		my $line = "  snmp: $msg\n";
		push @msg, $line;
	}
	if ( ($self->_get_plugin_check($ip)) && (! $self->_get_plugin_status($ip)) ) {
		my $msg = $self->_get_plugin_msg($ip);
		chomp $msg;
		my $line = "  plugin: $msg\n";
		push @msg, $line;
	}
	return(@msg);
}



1;
