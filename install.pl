#!/usr/bin/perl -w
#
# penemo install script, must be run as root.
#

use lib 'modules/';

use strict;
use IO::Handle;
use penemo;

unless ($< == 0) {
	print "This script must be run as ROOT!\n";
	exit;
}
else {
	print "\n [Installing penemo]\n\n";
	#system('umask 001');
	&main();
}

sub main {
	use penemo;
	my $conf = penemo::config->load_config('conf/penemo.conf', 
						'conf/agent.conf');
	my $conf_dir = '/usr/local/etc';
	my $cgibin_dir = $conf->get_cgibin_dir();

	my $cache_dir = $conf->get_cache_dir();
	my $data_dir = $conf->get_data_dir();
	my $html_dir = $conf->get_html_dir();
	my $plugin_dir = $conf->get_data_dir();

	print "installing config in $conf_dir/penemo/\n";
	&install_conf($conf_dir);
	print "creating penemo shared datafiles\n";
	&install_datafiles($cache_dir, $data_dir, $html_dir, $plugin_dir);
	print "copying penemo executable to /usr/local/sbin/\n";
	&install_exec();
	exit;
}

sub install_conf {
	my $conf_dir = shift;
	print "  creating directories...\n";
	if (-d $conf_dir) {
		unless (-d "$conf_dir/penemo") {
			print "    $conf_dir/penemo\n";
			system('mkdir $conf_dir/penemo');
		}
	}
	else {
		print "    $conf_dir\n";
		system("mkdir $conf_dir");
		print "    $conf_dir/penemo\n";
		system("mkdir $conf_dir/penemo");
	}

	print "  copying configuration files to $conf_dir/penemo/\n";
	unless ((-f "$conf_dir/penemo/agent.conf") || 
			(-f "$conf_dir/penemo/agent.conf")) {
		system('cp conf/penemo.conf $conf_dir/penemo/');
		system('cp conf/agent.conf $conf_dir/penemo/');
	}
	else {
		print "\n ** current configuration detected. please\n";
		print " ** remove the old configuration files in\n";
		print " ** $conf_dir/penemo/, and edit the config\n";
		print " ** in conf/ to reflect your preffered settings\n";
		print " ** then run this script again and the conf/agent.conf\n";
		print " ** and conf/penemo.conf will be used.\n\n";
		exit;
	}
}

sub install_datafiles {
	my ($cache_dir, $data_dir, $html_dir, $plugin_dir) = @_;
	unless (-d '/usr/local/share') {
		#print "creating /usr/local/share/\n";
		system('mkdir /usr/local/share');
	}

	unless (-d '/usr/local/share/penemo') {
		print "creating /usr/local/share/penemo/\n";
		system('mkdir /usr/local/share/penemo');
	}
	
	unless (-d $cache_dir) {
		print "   $cache_dir\n";
		system("mkdir $cache_dir");
	}
	unless (-d $html_dir) {
		print "   $html_dir\n";
		system("mkdir $html_dir/agentdump");
	}

	unless (-d "$html_dir/agentdump") {
		system("mkdir $html_dir");
		print "   $html_dir/agentdump/\n";
	}

	unless (-d "$html_dir/agents") {
		print "   $html_dir/agents/\n";
		system("mkdir $html_dir/agents");
	}
	
	unless (-d "$html_dir/images") {
		print "   $html_dir/images/\n";
		system("mkdir $html_dir/images");
		print "copying images to $html_dir/images/\n";
		system("cp html/images/*.gif $html_dir/images/");
	}

}

sub install_exec {
	system('cp bin/penemo /usr/local/sbin/');
	system('chmod u=rwx,g=rwx,o= /usr/local/sbin/penemo');

	sub install_cgi {
		my $cgibin_dir = shift;
		print "copying penemo-admin.cgi to $cgibin_dir\n";
		if (-d $cgibin_dir) {
			system("cp bin/penemo-admin.cgi $cgibin_dir/");
		}
		else {
			print "\n ** the directory $cgibin_dir doesn't exist\n";
			print "\n ** please edit the conf/penemo.conf file and\n";
			print "\n ** set the cgibin_dir option to the cgi-bin\n";
			print "\n ** that your instance of apache uses.\n";
			exit;
		}
	}
}

print "\nfinished installing penemo\n";



