#  modules/penemo.pm
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


############################
############################
############################
## core utilities
##
####
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
		return ("<IMG SRC=\"$path/green_button.gif\" BORDER=0 ALT=\"green\">");
	} 
	elsif ($name eq 'bad') { 
		return ("<IMG SRC=\"$path/red_button.gif\" BORDER=0 ALT=\"red\">");
	} 
	elsif ($name eq 'pause') { 
		return ("<IMG SRC=\"$path/blue_button.gif\" BORDER=0 ALT=\"blue\">");
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
		print MAIL "The error had fatal results, please fix asap.\n";
		print MAIL "\n"; 
		print MAIL $msg; 
		print MAIL "\n"; 
	close MAIL; 

	print "** dying...\n";
	die;
}


#############################
#############################
#############################
## the config class
##
####
####
####

package penemo::config;

use strict;

sub load_config
{
	my ($class, $penemo_conf, $agent_conf) = @_;
	my ($global_conf_ref, $agent_defaults_ref) = &_penemo_config("$penemo_conf");

	my %global_conf = %$global_conf_ref;
	my %agent_defaults = %$agent_defaults_ref;

	my $agent_ref = &_agent_config("$agent_conf", %agent_defaults);
	my %agents = %$agent_ref;

	my %conf = (%global_conf, %agents);

	my $ref = \%conf;
	bless $ref, $class;
}

sub _penemo_config
{
   my ($conf_file) = @_;
   my $key = '';
   my $value = '';
   my %conf = ( 
		notify_method_1 => 'email',
		notify_method_2 => 'email',
		notify_method_3 => 'email',
		notify_level    => '1',
		notify_email_1  => 'root@localhost',
		notify_email_2  => 'root@localhost',
		notify_email_3  => 'root@localhost',
		notify_exec_1	=> '',
		notify_exec_2	=> '',
		notify_exec_3	=> '',
		instance_name	=> 'default instance',
		http_command    => 'wget',
		snmp_community  => 'public',
		ping_timeout    => '1',
		html_dir        => '/usr/local/share/penemo/html',
		cache_dir       => '/usr/local/share/penemo/cache',
		data_dir	=> '/usr/local/share/penemo/data',
		penemo_bin      => '/usr/local/sbin/penemo',
		ucd_bin_dir     => '/usr/local/bin',
		plugin_dir	=> '/usr/local/share/penemo/plugin',
		errlev_reset	=> '1',
		tier_support	=> '0',
		tier_promote	=> '5',
		emergency_contact => 'root@localhost',
   );

   open(CFG, "$conf_file")
         or penemo::core->notify_die("Can't open $conf_file : $!\n");

   while (<CFG>)
   {
      next if ($_ =~ /^\s*#/);
      next if ($_ =~ /^$/);

      chomp;

      if ($_ =~ /^notify_exec/)
      {
         ($key, $value) = split(/_command\s*/, $_);
         $conf{'notify_exec'} = $value;
         next;
      }
      elsif ($_ =~ /^instance_name/)
      {
         ($key, $value) = split(/_name\s*/, $_);
	 $conf{'instance_name'} = $value;
	 next;
      }

      ($key, $value) = split(' ', $_);
      $conf{$key} = $value;
   }
   close CFG;
   
   my %agent = (
   		notify_method_1	=> $conf{notify_method_1},
   		notify_method_2	=> $conf{notify_method_2},
   		notify_method_3	=> $conf{notify_method_3},
   		notify_level 	=> $conf{notify_level},
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
		errlev_reset	=> $conf{errlev_reset},
		
   );

   my %global = ( default	=> {
					html_dir        => $conf{html_dir},
					cache_dir       => $conf{cache_dir},
					data_dir	=> $conf{data_dir},
					plugin_dir	=> $conf{plugin_dir},
					penemo_bin      => $conf{penemo_bin},
					ucd_bin_dir	=> $conf{ucd_bin_dir},
					http_command    => $conf{http_command},
					instance_name	=> $conf{instance_name},
					notification_stack	=> '',
					notification_org	=> [],
					tier_support	=> $conf{tier_support},
					tier_promote	=> $conf{tier_promote},
					emergency_contact => $conf{emergency_contact},
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
	my @lines = <CFG>;
        close CFG;
   
        chomp @lines;
        foreach my $line (@lines) {
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
                        $ip = '';
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
			&_agent_params(\%conf, $ip, 'plugin', $line);
			if ($conf{$ip}{plugin_mods}) {
				$conf{$ip}{plugin_check} = '1';
			}
		}
	}

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

# methods for load_config object. (global conf settings).
sub get_html_dir                { $_[0]->{default}{html_dir} }
sub get_cache_dir               { $_[0]->{default}{cache_dir} }
sub get_data_dir		{ $_[0]->{default}{data_dir} }
sub get_plugin_dir		{ $_[0]->{default}{plugin_dir} }
sub get_penemo_bin              { $_[0]->{default}{penemo_bin} }
sub get_ucd_bin_dir             { $_[0]->{default}{ucd_bin_dir} }
sub get_http_command            { $_[0]->{default}{http_command} }
sub get_instance_name		{ $_[0]->{default}{instance_name} }
sub get_tier_support		{ $_[0]->{default}{tier_support} }
sub get_tier_promote		{ $_[0]->{default}{tier_promote} }
sub get_emergency_contact	{ $_[0]->{default}{emergency_contact} }

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
sub _errlev_reset {
	my ($self, $ip) = @_;
	$self->{$ip}{errlev_reset};
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

	return penemo::agent->new( 
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
					group		=> $self->_group($ip),
					notify_method_1	=> $self->_notify_method_1($ip),
					notify_method_2	=> $self->_notify_method_2($ip),
					notify_method_3	=> $self->_notify_method_3($ip),
					notify_level	=> $self->_notify_level($ip),
					notify_email_1	=> $self->_notify_email_1($ip),
					notify_email_2	=> $self->_notify_email_2($ip),
					notify_email_3	=> $self->_notify_email_3($ip),
					notify_exec_1	=> $self->_notify_exec_1($ip),
					notify_exec_2	=> $self->_notify_exec_2($ip),
					notify_exec_3	=> $self->_notify_exec_3($ip),
					errlev_reset	=> $self->_errlev_reset($ip),
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


		unless ($self->get_tier_support()) {
			$method = $agent->get_notify_method_1();
			if ($method eq 'email') {
				$email = $agent->get_notify_email_1();
			}
			elsif ($method eq 'exec') {
				$exec = $agent->get_notify_exec_1();
			}
			$agent->set_notifications_sent('+');
		}
		else {
			$agent->set_notifications_sent('+');
			if ($agent->get_notifications_sent() >= $self->get_tier_promote()) {
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
		

		if ($agent->get_error_resolved()) {
			print "$ip, resolved problem\n";
			$self->{notification_org}{$email}{$ip}{resolved} = '1';
			$agent->set_notifications_sent('0');
			$agent->set_current_tier('1');
		}
		else {
			$self->{notification_org}{$email}{$ip}{resolved} = '0';
			$agent->set_have_notifications_been_sent('1');
		}

		
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
	my $index = $self->get_html_dir() . "/index.html";
	my $line = '';
	my $ok_light = penemo::core->html_image('index', 'ok'); 
	my $bad_light = penemo::core->html_image('index', 'bad'); 
	my $max_ip_length = 0;

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
		print HTML "\t<FONT SIZE=5><B><FONT COLOR=\"#CC11AA\">penemo</FONT> "; 
		print HTML "version $version</B></FONT>\n"; 
		print HTML "<HR WIDTH=60%>\n"; 
		print HTML "penemo last run: <FONT COLOR=\"#AAAAAA\">$date</FONT><BR>\n"; 
		print HTML "</CENTER>\n"; 

		print HTML "<FORM method=\"Post\" action=\"/cgi-bin/penemo-admin.cgi\">\n";
		print HTML "<TABLE WITH=600 ALIGN=CENTER BORDER=0>\n";
		foreach my $group (@grouplist) { 
			print HTML "<TR><TD WIDTH=600 ALIGN=LEFT COLSPAN=3>\n";
			print HTML "<FONT SIZE=4><B>$group</B><BR>\n"; 
			print HTML "</TD></TR>\n";
			foreach my $agent (@agentlist) { 
				my $ip = $agent->get_ip();
				if ($agent->get_group() eq "$group") { 
					print HTML "<TR><TD WIDTH=150 ALIGN=LEFT>\n";
					print HTML "<FONT SIZE=3 COLOR=\"#AAAAAA\">\n"; 
					if ($agent->get_index_error_detected()) { 
						print HTML "$bad_light  ";
					} 
					else { 
						print HTML "$ok_light  ";
					} 
					print HTML "<A HREF=\"agents/$ip/index.html\">$ip</A><BR>\n";
					print HTML "</TD>\n";
					print HTML "<TD WIDTH=400 ALIGN=LEFT>\n";
					print HTML "<FONT COLOR=#CCDDA><B>\n";
					print HTML $agent->get_name();
					print HTML "</B></FONT>\n"; 
					print HTML "</TD>\n";
					print HTML "<TD WIDTH=50 ALIGN=LEFT>\n";
					print HTML "<FONT SIZE=2>\n";
					print HTML "<A HREF=\"/cgi-bin/penemo-admin.cgi?agent=$ip&pause=1\">pause</A><BR>\n"; 
					print HTML "</FONT>\n";
					print HTML "</TD></TR>\n";
				} 
			} 
			print HTML "<TR><TD WIDTH=600 ALIGN=LEFT COLSPAN=3>\n";
			print HTML "&nbsp;<BR>\n"; 
			print HTML "</TD></TR>\n";
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


##################################
##################################
##################################
## the agent class.
##
####
####
####

package penemo::agent;

use lib '/home/nick/devel/penemo/modules/';

use penemo::snmp;
use penemo::plugin;

# nested sub for count methods
{
        my $_count = '0';
	my $_total_count = '0';

        # get count (number of agents created)
        sub get_count   	{ $_count }
	sub get_total_count	{ $_total_count }

        # internal counter
        sub _incr_count { ++$_count }
        sub _decr_count { --$_count }
        sub _incr_total_count { ++$_total_count }
}

sub new {
	my $class = shift;
	my %args = @_;

        my $self = bless {
                        ip		=> $args{ip},
			name		=> $args{name},
			ping_check	=> $args{ping_check},
                        ping_timeout	=> $args{ping_timeout},
			http_check	=> $args{http_check},
                        http_url	=> $args{http_url},
                        http_search	=> $args{http_search},
			snmp_check	=> $args{snmp_check},
                        snmp_community	=> $args{snmp_community},
                        snmp_mibs	=> $args{snmp_mibs},
			plugin_check	=> $args{plugin_check},
                        plugin_mods	=> $args{plugin_mods},
                        group		=> $args{group},
			notify_method_1	=> $args{notify_method_1},
			notify_method_2	=> $args{notify_method_2},
			notify_method_3	=> $args{notify_method_3},
			notify_level	=> $args{notify_level},
			notify_email_1	=> $args{notify_email_1},
			notify_email_2	=> $args{notify_email_2},
			notify_email_3	=> $args{notify_email_3},
			notify_exec_1	=> $args{notify_exec_1},
			notify_exec_2	=> $args{notify_exec_2},
			notify_exec_3	=> $args{notify_exec_3},
                        ping_status		=> '0',
			ping_errlev		=> '0',
                        ping_message		=> '',
                        http_status		=> '0',
                        http_get_status		=> '0',
			http_get_message	=> '',
                        http_search_status 	=> '0',
			http_search_message	=> '',
			http_errlev		=> '0',
                        snmp_status		=> {},
			snmp_errlev		=> '0',
                        snmp_message		=> {},
			snmp_html		=> {},
                        plugin_status		=> {},
			plugin_errlev		=> '0',
                        plugin_message		=> {},
			plugin_html		=> {},
			error_detected		=> '',
			index_error_detected	=> '',
			errlev_reset		=> $args{errlev_reset},
			current_tier		=> $args{current_tier},
			notifications_sent	=> '0',
			error_resolved		=> '0',
			have_notifications_been_sent	=> '0',
        }, $class;
	
        $self->_incr_count();
	$self->_incr_total_count();

	return $self;
}

sub load_persistent_data {
	my ($self, $data_dir) = @_;
	my $ip = $self->get_ip();

	if (-f "$data_dir/$ip")
	{ 
		open (DATA, "$data_dir/$ip") or penemo::core->notify_die("Can't open $data_dir/$ip: $!\n"); 
			my @lines = <DATA>;
		close DATA;
		my (@data) = split(/\s+/, $lines[0]); 
		$self->set_ping_errlev($data[0]);
		$self->set_http_errlev($data[1]);
		$self->set_snmp_errlev($data[2]);
		$self->set_plugin_errlev($data[3]);
		$self->set_current_tier($data[4]);
		$self->set_notifications_sent($data[5]);
print "\t\terror_levels: ping=$data[0], http=$data[1], snmp=$data[2] plugin=$data[3]\n";
print "\t\tcurrent_tier: $data[4], notifications_sent: $data[5]\n";
	}

	if ($self->get_notifications_sent()) {
		$self->set_have_notifications_been_sent('1');
	}
	
}

sub write_persistent_data {
	my ($self, $data_dir) = @_;
	my $ip = $self->get_ip();

	unless ($self->get_error_detected) { $self->set_current_tier('1'); }

	my $ping_errlev = $self->get_ping_errlev();
	my $http_errlev = $self->get_http_errlev();
	my $snmp_errlev = $self->get_snmp_errlev();
	my $plugin_errlev = $self->get_plugin_errlev();
	my $current_tier = $self->get_current_tier();
	my $notifications_sent = $self->get_notifications_sent();
	
	open (DATA, ">$data_dir/$ip") or penemo::core->notify_die("Can't open $data_dir/$ip: $!\n");
		print DATA "$ping_errlev\t$http_errlev\t$snmp_errlev\t$plugin_errlev\t$current_tier\t$notifications_sent\n";
	close DATA;
}


sub get_ip 			{ $_[0]->{ip} }
sub get_name			{ $_[0]->{name} }
sub get_group			{ $_[0]->{group} }
sub get_notify_method_1		{ $_[0]->{notify_method_1} }
sub get_notify_method_2		{ $_[0]->{notify_method_1} }
sub get_notify_method_3		{ $_[0]->{notify_method_1} }
sub get_notify_level		{ $_[0]->{notify_level} }
sub get_notify_email_1		{ $_[0]->{notify_email_1} }
sub get_notify_email_2		{ $_[0]->{notify_email_2} }
sub get_notify_email_3		{ $_[0]->{notify_email_3} }
sub get_notify_exec_1		{ $_[0]->{notify_exec_1} }
sub get_notify_exec_2		{ $_[0]->{notify_exec_2} }
sub get_notify_exec_3		{ $_[0]->{notify_exec_3} }
sub get_current_tier		{ $_[0]->{current_tier} }
sub set_current_tier { 
	my ($self, $set) = @_;
	if ($set eq '+') {
		$set = $self->get_current_tier();
		$set++;
	}
	#elsif ($set eq '0') {
	#	$set = '1';
	#}

	$self->{current_tier} = $set; 
}

sub get_notifications_sent	{ $_[0]->{notifications_sent} }
sub set_notifications_sent { 
	my ($self, $set) = @_;
	if ($set eq '+') {
		$set = $self->get_notifications_sent();
		$set++;
	}
	$self->{notifications_sent} = $set; 
}
sub get_error_resolved		{ $_[0]->{error_resolved} }
sub set_error_resolved {
	my ($self, $set) = @_;
	$self->{error_resolved} = $set;
}

# methods to check whether a poll on an agent was succesfull.
# and get the message output if applicable.
#

# returns a 0 if any errors in any check, 1 if not
sub get_check_status {
	my ($self) = @_;
	my $string = '';

	$string .= $self->get_ping_status()		if ($self->ping_check());
	$string .= $self->get_http_status()		if ($self->http_check());
	$string .= $self->get_total_snmp_status()	if ($self->snmp_check());
	$string .= $self->get_total_plugin_status()	if ($self->plugin_check());

	if ($string =~ /^\d*0\d*$/) {
		return 0;
	}
	return 1;
}

# if these (*_check subs) dont return 'yes' then the agent 
# isn't setup to perform that function.
#
sub ping_check 			{ $_[0]->{ping_check} }
sub http_check 			{ $_[0]->{http_check} } 
sub snmp_check 			{ $_[0]->{snmp_check} }
sub plugin_check 		{ $_[0]->{plugin_check} }

# ping check methods
sub get_ping_status             { $_[0]->{ping_status} }
sub get_ping_message            { $_[0]->{ping_message} }
sub get_ping_errlev             { $_[0]->{ping_errlev} }
sub get_ping_timeout 		{ $_[0]->{ping_timeout} }

# http check methods
sub get_http_status             { $_[0]->{http_status} }
sub get_http_get_status         { $_[0]->{http_get_status} }
sub get_http_search_status      { $_[0]->{http_search_status} }
sub get_http_message            { $_[0]->{http_message} }
sub get_http_get_message        { $_[0]->{http_get_message} }
sub get_http_search_message     { $_[0]->{http_search_message} }
sub get_http_url 		{ $_[0]->{http_url} }
sub get_http_search 		{ $_[0]->{http_search} }
sub get_http_command 		{ $_[0]->{http_command} }
sub get_http_errlev             { $_[0]->{http_errlev} }

# snmp check methods
sub get_total_snmp_status {
	my ($self) = @_;
	unless ($self->snmp_check()) { return 1; }
	my @mibs = split(/ /, $self->get_snmp_mibs());
	foreach my $mib (@mibs) {
		unless ($self->get_snmp_status($mib)) {	
			return 0;
		}
	}
	return 1;
}
sub get_snmp_status { 
	my ($self, $mib) = @_;
	$self->{snmp_status}{$mib}; 
}
sub get_snmp_message {
	my ($self, $mib) = @_;
	$self->{snmp_message}{$mib}; 

}
sub get_snmp_errlev             { $_[0]->{snmp_errlev} }
sub get_snmp_mibs		{ $_[0]->{snmp_mibs} }
sub get_snmp_community		{ $_[0]->{snmp_community} }

# plugin check methods
sub get_total_plugin_status {
	my ($self) = @_;
	unless ($self->plugin_check()) { return 1; }
	my @mods = split(/ /, $self->get_plugin_mods());
	foreach my $mod (@mods) {
		unless ($self->get_plugin_status($mod)) {	
			return 0;
		}
	}
	return 1;
}
sub get_plugin_status { 
	my ($self, $mod) = @_;
	$self->{plugin_status}{$mod}; 
}
sub get_plugin_message {
	my ($self, $mob) = @_;
	$self->{plugin_message}{$mob}; 
}
sub get_plugin_errlev           { $_[0]->{plugin_errlev} }
sub get_plugin_mods		{ $_[0]->{plugin_mods} }



sub get_errlev_reset		{ $_[0]->{errlev_reset} }
sub get_error_detected		{ $_[0]->{error_detected} }
sub get_index_error_detected	{ $_[0]->{index_error_detected} }
sub set_error_detected { 
	$_[0]->{error_detected} = '1'; 
	$_[0]->{index_error_detected} = '1';
}
sub set_index_error_detected 	{ $_[0]->{index_error_detected} = '1'; }
sub set_have_notifications_been_sent {
	$_[0]->{have_notifications_been_sent} = $_[1];
}
sub have_notifications_been_sent 	{ $_[0]->{have_notifications_been_sent} }


# set the status and message values when an
# agent is polled (for internal method use only)
#
sub _set_ping_status {
	my ($self, $set) = @_;
	$self->{ping_status} = $set;
}
sub _set_ping_message {
	my ($self, $set) = @_;
	$self->{ping_message} = $set;
}
sub _set_http_status {
	my ($self, $set) = @_;
	$self->{http_status} = $set;
}
sub _set_http_get_status {
	my ($self, $set) = @_;
	$self->{http_get_status} = $set;
}
sub _set_http_search_status {
	my ($self, $set) = @_;
	$self->{http_search_status} = $set;
}
sub _set_http_get_message {
	my ($self, $set) = @_;
	$self->{http_get_message} = $set;
}
sub _set_http_search_message {
	my ($self, $set) = @_;
	$self->{http_search_message} = $set;
}
sub _set_snmp_message {
	my ($self, $mib, $set) = @_;
	$self->{snmp_message}{$mib} = $set;
}
sub _set_snmp_status {
	my ($self, $mib, $set) = @_;
	$self->{snmp_status}{$mib} = $set;
}
sub _set_plugin_message {
	my ($self, $mod, $set) = @_;
	$self->{plugin_message}{$mod} = $set;
}
sub _set_plugin_status {
	my ($self, $mod, $set) = @_;
	$self->{plugin_status}{$mod} = $set;
}


sub set_ping_errlev {
	my ($self, $set) = @_;
	if ($set =~ /^\+$/)
	{
		$set = $self->get_ping_errlev();
		$set++;
	}
	$self->{ping_errlev} = $set;
}
sub set_http_errlev {
	my ($self, $set) = @_;
	if ($set =~ /^\+$/)
	{
		$set = $self->get_http_errlev() + 1;
	}
	$self->{http_errlev} = $set;
}
sub set_snmp_errlev {
	my ($self, $set) = @_;
	if ($set =~ /^\+$/)
	{
		$set = $self->get_snmp_errlev() + 1;
	}
	$self->{snmp_errlev} = $set;
}
sub set_plugin_errlev {
	my ($self, $set) = @_;
	if ($set =~ /^\+$/)
	{
		$set = $self->get_plugin_errlev() + 1;
	}
	$self->{plugin_errlev} = $set;
}




# destroy object
#
sub DESTROY {
        my ($self) = @_;
        $self->_decr_count();
        print "dead: ", $self->name(), "\n";
}



####
####
## get values of polled object
## agent polling methods.
####
####

# ping agent, return status.
sub ping {
        use Net::Ping;

        my $self = $_[0];
        my ($ip, $pings) = ( $self->get_ip, $self->get_ping_timeout() );
        my $pingobj = Net::Ping->new( $> ? "udp" : "icmp", $pings);

        my $stat;
        my $msg;

        if ($pingobj->ping($ip)) {
                $pingobj->close();
                my @temp = `ping -c $pings $ip`;
                chomp $temp[1];
                $stat = '1';
                $msg = $temp[1];
        }
        else {
                $pingobj->close();
                $stat = '0';
                $msg = 'Unsuccessful';
		$self->set_ping_errlev('+');
        }

        $self->_set_ping_status("$stat");
	$self->_set_ping_message("$msg"); 

}


# performs a http request on sepcified URL, and then performs a search
# on the retrieved file for specified string.
sub http {
   my ($self, $command, $cache) = @_;
   my $url = $self->get_http_url(); 
   my $check = '';

   if (! $command) {
      $self->_set_http_status("0");
      $self->_set_http_get_status("0");
      $self->_set_http_get_message("http command not set in penemo.conf");
      $self->set_http_errlev('999');
      return;
   }

   # command line args for supported http fetchers
   if ($command eq 'snarf') {
      $check = system("snarf -q -n http://$url $cache/search.html");
   }
   elsif ($command eq 'fetch') {
      $check = system("fetch -q -o $cache/search.html http://$url");
   }
   elsif ($command eq 'wget') {
      $check = system("wget -q -t 1 -T 20 -O $cache/search.html http://$url");
   }

   if ($check != 0) {
      $self->_set_http_status("0");
      $self->_set_http_get_status("0");
      $self->_set_http_get_message("failed with http request, url: $url");
      $self->set_http_errlev('+');
      return;
   }
   else {
      $self->_set_http_status("1");
      $self->_set_http_get_status("1");
   }

   # begin search part of http function, if search
   # string is true.

   unless ( ($self->get_http_search()) && ($self->get_http_status()) ) {
	if (-f "$cache/search.html") {
		system("rm $cache/search.html");
	}
	return;
   }
   
   my $string = $self->get_http_search();

   open(SEARCH, "$cache/search.html")
        or penemo::core->notify_die("Couldnt open $cache/search.html : $!\n");
   my $return = '0';
   while (<SEARCH>) {
      if ($_ =~ /$string/) {
         $return = '1';
         last;
      }
   }
   close SEARCH;
   unless ($return == '1') {
      $return = '0';
      $self->_set_http_search_message("failed search for: $string, at url: $url\n");
   }

   if (-f "$cache/search.html") {
      system("rm $cache/search.html");
   }

   $self->_set_http_search_status($return);
   $self->_set_http_status($return);
   $self->set_http_errlev('+');
}

# snmp polling function.
sub snmp {
        my ($self, $plugin_dir, $ucd_bin_dir) = @_;
        my $ip        = $self->get_ip;
	my $community = $self->get_snmp_community();
	my (@mibs) = split(/ /, $self->get_snmp_mibs());
	my $error_detected = 0;
	
	foreach my $mib (@mibs) {
		my $snmp = penemo::snmp->new(
						mib => $mib,
						community => $community,
						ip => $ip,
						plugin_dir => $plugin_dir,
						ucd_bin_dir => $ucd_bin_dir,
		);

		$snmp->poll();
	
		unless ($snmp->status()) {
			$self->_set_snmp_status($mib, '0');
			$self->_set_snmp_message($mib, $snmp->message());
			$error_detected = 1;
		}
		else {
			$self->_set_snmp_status($mib, '1');
			$self->_set_snmp_message($mib, $snmp->message());
			$self->_set_snmp_html($mib, $snmp->html());
		}
	}
	if ($error_detected) {
		$self->set_snmp_errlev('+');
	}
}


# plugin module execution function.
sub plugin {
        my ($self, $plugin_dir) = @_;
        my $ip        = $self->get_ip;
	my (@mods) = split(/ /, $self->get_plugin_mods());
	my $error_detected = 0;
	
	foreach my $mod (@mods) {
		my $plugin = penemo::plugin->new(
						mod => $mod,
						ip => $ip,
						plugin_dir => $plugin_dir,
		);

		$plugin->exec();
	
		unless ($plugin->status()) {
			$self->_set_plugin_status($mod, '0');
			$self->_set_plugin_message($mod, $plugin->message());
			$error_detected = 1;
		}
		else {
			$self->_set_plugin_status($mod, '1');
			$self->_set_plugin_message($mod, $plugin->message());
			$self->_set_plugin_html($mod, $plugin->html());
		}
	}
	if ($error_detected) {
		$self->set_plugin_errlev('+');
	}
}

sub agent_html_write
{
	my ($self, $html_dir) = @_;
	my $ip = $self->get_ip();
	my $name = $self->get_name();

	my $ok_light = penemo::core->html_image('agent', 'ok'); 
	my $bad_light = penemo::core->html_image('agent', 'bad'); 

	unless (-d "$html_dir/agents/$ip") { 
		system("mkdir $html_dir/agents/$ip") 
	}

	open(HTML, ">$html_dir/agents/$ip/index.html") 
		or penemo::core->notify_die("Can't open $html_dir/agents/$ip/index.html to write: $!\n"); 

	print HTML "<HTML>\n"; 
	print HTML "<HEAD>\n"; 
	print HTML "\t<TITLE>penemo -- Status on $ip</TITLE>\n"; 
	print HTML "</HEAD>\n"; 
	print HTML "<BODY BGCOLOR=\"#000000\" TEXT=\"#338877\" "; 
	print HTML "LINK=\"#AAAAAA\" VLINK=\"#AAAAAA\">\n"; 
	print HTML "<CENTER>\n"; 
	print HTML "\t<FONT SIZE=5><B>$ip - $name</B></FONT>\n"; 
	print HTML "<HR WITH=50%>\n"; 

	unless ($self->snmp_check()) { 
		print HTML "[not an snmp aware device]<BR>\n"; 
	} 
	else { 
		my @mibs = split(/ /, $self->get_snmp_mibs());
		if (-f "$html_dir/agentdump/$ip") {
			system("rm $html_dir/agentdump/$ip");
		}
		foreach my $mib (@mibs) {
			if (-f "$html_dir/agentdump/$ip") {
			}
			penemo::core->file_write(">>$html_dir/agentdump/$ip", $self->get_snmp_message($mib));
		}
		print HTML "[<A HREF=\"$html_dir/agentdump/$ip\">current snmp info</A>]<BR>\n"; 
	} 
	
	print HTML "</CENTER>\n"; 
	print HTML "&nbsp;<BR>\n"; 
	
	# ping info 
	# 
	unless ($self->get_ping_status()) { 
		$self->set_index_error_detected();
		print HTML "<FONT COLOR=\"#AAAAAA\" SIZE=1><I>PING</I></FONT><BR>\n";
		print HTML "$bad_light\n";
		print HTML "<FONT COLOR=\"#DD1111\">Can't ping $ip !! "; 
		print HTML "Machine might be down!</FONT><BR>\n"; 
		print HTML "<BR>\n";
	} 
	elsif ($self->ping_check()) { 
		print HTML "<FONT COLOR=\"#AAAAAA\" SIZE=1><I>PING</I></FONT><BR>\n";
		print HTML "$ok_light\n"; 
		print HTML "<FONT COLOR=\"#11AA11\">", $self->get_ping_message(), "</FONT><BR>\n"; 
		print HTML "<BR>\n";
	} 

	# http info
	#
	if ($self->http_check()) {
		print HTML "<FONT COLOR=\"#AAAAAA\" SIZE=1><I>HTTP</I></FONT><BR>\n";
		if ($self->get_http_get_status()) {
			unless ($self->get_http_search()) {
				print HTML "$ok_light\n";
				print HTML "<FONT COLOR=\"#11AA11\">HTTP succesful fetching url: ", 
					"</FONT><FONT COLOR=\#33FF33\">", $self->get_http_url(), 
					"</FONT><BR>\n";
			}
			elsif ($self->get_http_search_status()) { 
				print HTML "$ok_light\n";
				print HTML "<FONT COLOR=\"#11AA11\">HTTP search succesful: ", 
					"<FONT COLOR=\#33FF33\">", $self->get_http_search(), 
					"</FONT> found at url: </FONT><FONT COLOR=\#33FF33\">", 
					$self->get_http_url(), "</FONT><BR>\n";
			}
			else {
				$self->set_index_error_detected();
				print HTML "$bad_light\n";
				print HTML "<FONT COLOR=\"#DD1111\">",
					"HTTP search failed finding string: ", 
					"<FONT COLOR=\#FF5555\">", $self->get_http_url(), 
					"</FONT> at url: </FONT><FONT COLOR=\#FF5555\">", 
					$self->get_http_url(), "</FONT><BR>\n";
			}

		}
		else { 
			$self->set_index_error_detected();
			print HTML "$bad_light\n";
			print HTML "<FONT COLOR=\"#DD1111\">HTTP failed fetching url: ", 
					"</FONT><FONT COLOR=\"#FF5555\">", $self->get_http_url(), 
					"</FONT><BR>\n";
		}	
		print HTML "<BR>\n";
	}

	# snmp info
	#
	if ($self->snmp_check()) {
		my $mib_list  = $self->get_snmp_mibs();
		my (@mibs) = split(/ /, $mib_list);
		print HTML "<FONT COLOR=\"#AAAAAA\" SIZE=1><I>SNMP</I></FONT><BR>\n";

		foreach my $mib (@mibs) {
			if ($self->get_snmp_status($mib)) {
				print HTML $self->_print_snmp_html($mib);
			}
			else {
				$self->set_index_error_detected();
				print HTML "$bad_light\n";
				print HTML "<FONT COLOR=\"#DD1111\"> ", $self->get_snmp_message($mib),
					"</FONT><BR>\n";
			}
			print HTML "<BR>\n";
		}
	}

	# plugin info
	#
	if ($self->plugin_check()) {
		my $mod_list  = $self->get_plugin_mods();
		my (@mods) = split(/ /, $mod_list);
		print HTML "<FONT COLOR=\"#AAAAAA\" SIZE=1><I>PLUGINS</I></FONT><BR>\n";

		foreach my $mod (@mods) {
			if ($self->get_plugin_status($mod)) {
				print HTML $self->_print_plugin_html($mod);
			}
			else {
				$self->set_index_error_detected();
				print HTML "$bad_light\n";
				print HTML "<FONT COLOR=\"#DD1111\"> ", $self->get_plugin_message($mod),
					"</FONT><BR>\n";
			}
			print HTML "<BR>\n";
		}
	}
}


sub _set_snmp_html {
	my ($self, $mib, @html) = @_;
	$self->{snmp_html}{"$mib"} = "@html";
}
sub _print_snmp_html { 
	my ($self, $mib) = @_;
	$self->{snmp_html}{"$mib"};
} 

sub _set_plugin_html {
	my ($self, $mod, @html) = @_;
	$self->{plugin_html}{"$mod"} = "@html";
}
sub _print_plugin_html { 
	my ($self, $mod) = @_;
	$self->{plugin_html}{"$mod"};
} 


###################
###################
###################
## notify class
##
####
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
		}
	}
	my $to = $self->get_method();
		
	print "  @msg\n";

        open(MAIL, "| /usr/sbin/sendmail -t -oi") 
			or penemo::core->notify_die("Can't send notification email : $!\n"); 
		print MAIL "To: $to\n"; 
		print MAIL "From: penemo-notify\n";
		print MAIL "Subject: $instance Problem!\n"; 
		print MAIL "tier level: ", $self->_get_current_tier(), "\n";
		print MAIL "tier email: $to\n";
		print MAIL "  The following errors were encountered\n"; 
		print MAIL "during the execution of penemo $version.\n"; 
		print MAIL "\n"; 
		print MAIL @msg; 
		print MAIL "\n"; 
	close MAIL; 

}

sub execute {
	print "execute method not implemented.\n";
}



1;
