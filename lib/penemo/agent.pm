# modules/penemo/agent.pm
#

##################################
##################################
##################################
## the agent class.
##
####
####
####

package penemo::agent;
#use lib '/usr/local/share/penemo/modules/';

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
			notify_cap	=> $args{notify_cap},
			notify_email_1	=> $args{notify_email_1},
			notify_email_2	=> $args{notify_email_2},
			notify_email_3	=> $args{notify_email_3},
			notify_exec_1	=> $args{notify_exec_1},
			notify_exec_2	=> $args{notify_exec_2},
			notify_exec_3	=> $args{notify_exec_3},
			notify_errlev_reset	=> $args{notify_errlev_reset},
			tier_support		=> $args{tier_support},
			tier_promote		=> $args{tier_promote},
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
			snmp_walk		=> {},
                        snmp_message		=> {},
			snmp_html		=> {},
                        plugin_status		=> {},
			plugin_errlev		=> '0',
                        plugin_message		=> {},
			plugin_html		=> {},
			error_detected		=> '',
			index_error_detected	=> '',
			notify_errlev_reset		=> $args{notify_errlev_reset},
			current_tier		=> $args{current_tier},
			notifications_sent	=> '0',
			error_resolved		=> '0',
			have_notifications_been_sent	=> '0',
			paused			=> '',
			paused_end		=> '',
			on_notify_stack		=> 0,
        }, $class;
	
        $self->_incr_count();
	$self->_incr_total_count();

	return $self;
}

#
# object interface methods
#

sub load_persistent_data {
	my ($self, $dir_data) = @_;
	my $ip = $self->get_ip();

	if (-f "$dir_data/$ip")
	{ 
		open (DATA, "$dir_data/$ip") or penemo::core->notify_die("Can't open $dir_data/$ip: $!\n"); 
			my @lines = <DATA>;
		close DATA;
		my (@data) = split(/\s+/, $lines[0]); 
		$self->set_ping_errlev($data[0]);
		$self->set_http_errlev($data[1]);
		$self->set_snmp_errlev($data[2]);
		$self->set_plugin_errlev($data[3]);
		$self->set_current_tier($data[4]);
		$self->set_notifications_sent($data[5]);
		$self->set_paused($data[6]);
		$self->set_paused_end($data[7]); 	# YYYYMMDDHHMM - the time when the agent unpauses.

print "\t\terror_levels: ping: $data[0], http: $data[1], snmp: $data[2], plugin: $data[3]\n";
print "\t\tcurrent_tier: $data[4], notifications_sent: $data[5]\n";
	}

	if ($self->get_notifications_sent()) {
		$self->set_have_notifications_been_sent('1');
	}
	
}

sub write_persistent_data {
	my ($self, $dir_data) = @_;
	my $ip = $self->get_ip();

	unless ($self->get_error_detected) { $self->set_current_tier('1'); }

	my $ping_errlev = $self->get_ping_errlev();
	my $http_errlev = $self->get_http_errlev();
	my $snmp_errlev = $self->get_snmp_errlev();
	my $plugin_errlev = $self->get_plugin_errlev();
	my $current_tier = $self->get_current_tier();
	my $notifications_sent = $self->get_notifications_sent();
	my $paused = $self->get_paused();
	my $paused_end = $self->get_paused_end();
	
	open (DATA, ">$dir_data/$ip") or penemo::core->notify_die("Can't open $dir_data/$ip: $!\n");
		print DATA "$ping_errlev\t$http_errlev\t$snmp_errlev\t$plugin_errlev\t$current_tier\t$notifications_sent\t$paused\t$paused_end\n";
	close DATA;

	system("chmod g=rw $dir_data/$ip");
}


sub get_ip 			{ $_[0]->{ip} }
sub get_name			{ $_[0]->{name} }
sub get_group			{ $_[0]->{group} }
sub get_notify_method_1		{ $_[0]->{notify_method_1} }
sub get_notify_method_2		{ $_[0]->{notify_method_1} }
sub get_notify_method_3		{ $_[0]->{notify_method_1} }
sub get_notify_level		{ $_[0]->{notify_level} }
sub get_notify_cap		{ $_[0]->{notify_cap} }
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
sub get_tier_support	{ $_[0]->{tier_support} }
sub get_tier_promote	{ $_[0]->{tier_promote} }

sub get_on_notify_stack		{ $_[0]->{on_notify_stack} }
sub set_on_notify_stack {
	my ($self, $set) = @_;
	$self->{on_notify_stack} = $set;
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
# pausing functions
sub get_paused		{ $_[0]->{paused} }
sub set_paused { 
	my ($self, $set) = @_;
	$self->{paused} = $set; 
}
# value is YYYYMMDDHHMM -- the date the agent will unpause.
sub get_paused_end	{ $_[0]->{paused_end} }
sub set_paused_end { 
	my ($self, $set) = @_;
	$self->{paused_end} = $set; 
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
sub get_snmp_walk {
	my ($self, $mib) = @_;
	$self->{snmp_walk}{$mib}; 
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
sub get_notify_errlev_reset	{ $_[0]->{notify_errlev_reset} }
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


#
# internal object methods
#
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
sub _set_snmp_walk {
	my ($self, $mib, $set) = @_;
	$self->{snmp_walk}{$mib} = $set;
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
   $url =~ s/http:\/\///g;
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
      $check = system("fetch -T 5 -q -o $cache/search.html http://$url");
   }
   elsif ($command eq 'wget') {
      $check = system("wget -q -t 1 -T 20 -O $cache/search.html http://$url");
   }

   if ($check != 0) {
      $self->_set_http_status("0");
      $self->_set_http_get_status("0");
      $self->_set_http_get_message("failed url: $url");
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
        or penemo::core->notify_die("Cant open $cache/search.html : $!\n");
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
        my ($self, $dir_plugin, $dir_ucd_bin) = @_;
        my $ip        = $self->get_ip;
	my $community = $self->get_snmp_community();
	my (@mibs) = split(/ /, $self->get_snmp_mibs());
	my $error_detected = 0;
	use penemo::agent::snmp;
	
	foreach my $mib (@mibs) {
		if ($mib eq 'mib-2') {$mib = 'mib2';}
		require "penemo/agent/snmp/$mib.pm";
		my $snmp = "penemo::agent::snmp::$mib"->new(
						community => $community,
						ip => $ip,
						dir_ucd_bin => $dir_ucd_bin,
		);
		if ($mib eq 'mib2') {$mib = 'mib-2';}

		$snmp->poll();
	
		unless ($snmp->status()) {
			$self->_set_snmp_status($mib, '0');
			$self->_set_snmp_message($mib, $snmp->message());
			$self->_set_snmp_walk($mib, $snmp->walk());
			$self->_set_snmp_html($mib, $snmp->html());
			$error_detected = 1;
		}
		else {
			$self->_set_snmp_status($mib, '1');
			$self->_set_snmp_message($mib, $snmp->message());
			$self->_set_snmp_walk($mib, $snmp->walk());
			$self->_set_snmp_html($mib, $snmp->html());
		}
	}
	if ($error_detected) {
		$self->set_snmp_errlev('+');
	}
}


# plugin module execution function.
sub plugin {
        my ($self, $dir_plugin) = @_;
        my $ip        = $self->get_ip;
	my (@mods) = split(/ /, $self->get_plugin_mods());
	my $error_detected = 0;
	
	foreach my $mod (@mods) {
		require "penemo/agent/$mod.pm";
		my $plugin = "penemo::agent::$mod"->new(
						mod => $mod,
						ip => $ip,
						dir_plugin => $dir_plugin,
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

sub write_agent_history {
	my ($self, $dir_html, $entry) = @_;
	my $ip = $self->get_ip();
	if ($entry eq 'date') {
		$entry = "date: " . `date`;
	}
	chomp $entry;

	unless (-d "$dir_html/agents") {
		system("mkdir $dir_html/agents");
	}
	unless (-d "$dir_html/agents/$ip") {
		system("mkdir $dir_html/agents/$ip");
	}
	unless (-d "$dir_html/agents/$ip/history") {
		system("mkdir $dir_html/agents/$ip/history");
	}

	open (HISTORY, ">>$dir_html/agents/$ip/history/index.html") 
 			or penemo::core->notify_die("Cant open $dir_html/agents/$ip/history/index.html : $!\n");
		print HISTORY "$entry<BR>\n";
	close HISTORY;
}



sub write_agent_html
{
	my ($self, $dir_html) = @_;
	my $ip = $self->get_ip();
	my $name = $self->get_name();

	my $ok_light = penemo::core->html_image('agent', 'ok'); 
	my $bad_light = penemo::core->html_image('agent', 'bad'); 
	my $warn_light = penemo::core->html_image('agent', 'warn'); 

	unless (-d "$dir_html/agents") { 
		system("mkdir $dir_html/agents"); 
	}

	unless (-d "$dir_html/agents/$ip") { 
		system("mkdir $dir_html/agents/$ip"); 
	}

	# write agents conf.html
	#
	open(CONF, ">$dir_html/agents/$ip/conf.html") 
		or penemo::core->notify_die("Can't open $dir_html/agents/$ip/conf.html to write: $!\n"); 
	print CONF "<HTML>\n"; 
	print CONF "<HEAD>\n"; 
	print CONF "\t<TITLE>penemo -- Status on $ip</TITLE>\n"; 
	print CONF "</HEAD>\n"; 
	print CONF "<BODY BGCOLOR=\"#000000\" TEXT=\"#338877\" "; 
	print CONF "LINK=\"#AAAAAA\" VLINK=\"#AAAAAA\">\n"; 
	print CONF "<CENTER>\n"; 
	print CONF "\t<FONT SIZE=5><B>$ip - $name</B></FONT>\n"; 
	print CONF "<HR WIDTH=50%>\n"; 
	print CONF "</CENTER>\n"; 
	print CONF "&nbsp;<BR>\n";
	print CONF "<B>group</B>: <FONT COLOR=#6666AA>", $self->get_group(), "</FONT><BR>\n";;
	print CONF "<B>checks</B>:<I><FONT COLOR=#6666AA>";
	if ($self->ping_check()) { print CONF " ping"; }
	if ($self->http_check()) { print CONF ", http"; }
	if ($self->snmp_check()) { 
		print CONF ", snmp: "; 
		print CONF $self->get_snmp_mibs();
	}
	if ($self->plugin_check()) { 
		print CONF ", plugin "; 
		print CONF $self->get_plugin_mods();
	}
	print CONF "</FONT></I><BR>\n";

	print CONF "<B>error levels</B>: ";
	print CONF "ping: <FONT COLOR=#6666AA>", $self->get_ping_errlev(), "</FONT>, ";
	print CONF "http: <FONT COLOR=#6666AA>", $self->get_http_errlev(), "</FONT>, ";
	print CONF "snmp: <FONT COLOR=#6666AA>", $self->get_snmp_errlev(), "</FONT>, ";
	print CONF "plugin: <FONT COLOR=#6666AA>", $self->get_plugin_errlev(), "</FONT> ";
	print CONF "<BR>&nbsp;<BR>\n";

	print CONF "<B>tier support</B>: <FONT COLOR=#AA4444>", $self->get_tier_support(), "</FONT>";
	if ($self->get_tier_support()) {
		print CONF "&nbsp &nbsp promote tier after <FONT COLOR=#6666AA>", $self->get_tier_promote(), "</FONT> notifications";
	}
	print CONF "<BR>&nbsp;<BR>\n";

	print CONF "<B>current tier</B>: <FONT COLOR=#6666AA>", $self->get_current_tier(), "</FONT>";
	print CONF "<BR>\n";
	print CONF "<B>notifications sent</B>: <FONT COLOR=#6666AA>", $self->get_notifications_sent(), "</FONT>";
	print CONF "<BR>\n";
	print CONF "<B>notify level</B>: <FONT COLOR=#6666AA>", $self->get_notify_level(), "</FONT>";
	print CONF "<BR>\n";
	print CONF "<B>notify cap</B>: <FONT COLOR=#6666AA>", $self->get_notify_cap(), "</FONT>";
	print CONF "<BR>&nbsp;<BR>\n";
	print CONF "<B>notify errlev_reset</B>: <FONT COLOR=#AA4444>", $self->get_notify_errlev_reset(), "</FONT>";
	print CONF "<BR>\n";

	print CONF "&nbsp;<BR>\n";
	print CONF "<B>Tier 1</B><BR>";
	print CONF "&nbsp &nbsp <I>notify method</I>: <FONT COLOR=#6666AA>", $self->get_notify_method_1(), "</FONT>";
	if ($self->get_notify_method_1() eq 'email') {
		print CONF " <B>:</B> <FONT COLOR=#6666AA>", $self->get_notify_email_1(), "</FONT><BR>";
	}
	else {
		# exec
	}
	print CONF "<B>Tier 2</B><BR>";
	print CONF "&nbsp &nbsp <I>notify method</I>: <FONT COLOR=#6666AA>", $self->get_notify_method_2(), "</FONT>";
	if ($self->get_notify_method_1() eq 'email') {
		print CONF " <B>:</B> <FONT COLOR=#6666AA>", $self->get_notify_email_2(), "</FONT><BR>";
	}
	else {
		# exec
	}
	print CONF "<B>Tier 3</B><BR>";
	print CONF "&nbsp &nbsp <I>notify method</I>: <FONT COLOR=#6666AA>", $self->get_notify_method_3(), "</FONT>";
	if ($self->get_notify_method_1() eq 'email') {
		print CONF " <B>:</B> <FONT COLOR=#6666AA>", $self->get_notify_email_3(), "</FONT><BR>";
	}
	else {
		# exec
	}


	print CONF "</BODY></HTML>\n";
	close CONF;

	# write agents index.html
	#
	open(HTML, ">$dir_html/agents/$ip/index.html") 
		or penemo::core->notify_die("Can't open $dir_html/agents/$ip/index.html to write: $!\n"); 

	print HTML "<HTML>\n"; 
	print HTML "<HEAD>\n"; 
	print HTML "\t<TITLE>penemo -- Status on $ip</TITLE>\n"; 
	print HTML "</HEAD>\n"; 
	print HTML "<BODY BGCOLOR=\"#000000\" TEXT=\"#338877\" "; 
	print HTML "LINK=\"#AAAAAA\" VLINK=\"#AAAAAA\">\n"; 
	print HTML "<CENTER>\n"; 
	print HTML "\t<FONT SIZE=5><B>$ip - $name</B></FONT>\n"; 
	print HTML "<HR WIDTH=50%>\n"; 

	print HTML "[<A HREF=\"conf.html\">current agent config</A>]  \n"; 
	if ($self->snmp_check()) { 
		my @mibs = split(/ /, $self->get_snmp_mibs());
		unless (-d "$dir_html/agentdump") {
			system("mkdir $dir_html/agentdump");
		}
		if (-f "$dir_html/agentdump/$ip") {
			system("rm $dir_html/agentdump/$ip");
		}
		foreach my $mib (@mibs) {
			if (-f "$dir_html/agentdump/$ip") {
			}
			penemo::core->file_write(">>$dir_html/agentdump/$ip", $self->get_snmp_walk($mib));
		}
		print HTML "[<A HREF=\"../../agentdump/$ip\">current snmp info</A>]<BR>\n"; 
	} 
	else {
		print HTML "<BR>\n";
	}
	
	print HTML "</CENTER>\n"; 
	print HTML "&nbsp;<BR>\n"; 
	
	# ping info 
	# 
	if ($self->ping_check()) { 
		unless ($self->get_ping_status()) { 
			$self->set_index_error_detected();
			print HTML "<FONT COLOR=\"#AAAAAA\" SIZE=1><I>PING</I></FONT><BR>\n";
			if ($self->get_on_notify_stack()) {
				print HTML "$bad_light\n";
			}
			else {
				print HTML "$warn_light\n";
			}
			print HTML "<FONT COLOR=\"#DD1111\">Can't ping $ip !! "; 
			print HTML "Machine might be down!</FONT><BR>\n"; 
			print HTML "<BR>\n";
		} 
		else {
			print HTML "<FONT COLOR=\"#AAAAAA\" SIZE=1><I>PING</I></FONT><BR>\n";
			print HTML "$ok_light\n"; 
			print HTML "<FONT COLOR=\"#11AA11\">", $self->get_ping_message(), "</FONT><BR>\n"; 
			print HTML "<BR>\n";
		}
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
				if ($self->get_on_notify_stack()) {
					print HTML "$bad_light\n";
				}
				else {
					print HTML "$warn_light\n";
				}

				print HTML "<FONT COLOR=\"#DD1111\">",
					"HTTP search failed finding string: ", 
					"<FONT COLOR=\#FF5555\">", $self->get_http_url(), 
					"</FONT> at url: </FONT><FONT COLOR=\#FF5555\">", 
					$self->get_http_url(), "</FONT><BR>\n";
			}

		}
		else { 
			$self->set_index_error_detected();
			if ($self->get_on_notify_stack()) {
				print HTML "$bad_light\n";
			}
			else {
				print HTML "$warn_light\n";
			}

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
			if ($self->_print_snmp_html($mib)) {
				print HTML $self->_print_snmp_html($mib);
			}
			else {
				$self->set_index_error_detected();
				if ($self->get_on_notify_stack()) {
					print HTML "$bad_light\n";
				}
				else {
					print HTML "$warn_light\n";
				}

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
				if ($self->get_on_notify_stack()) {
					print HTML "$bad_light\n";
				}
				else {
					print HTML "$warn_light\n";
				}

				print HTML "<FONT COLOR=\"#DD1111\"> ", $self->get_plugin_message($mod),
					"</FONT><BR>\n";
			}
			print HTML "<BR>\n";
		}
	}
	close HTML;
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


1;
