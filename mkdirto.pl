#!/usr/bin/perl -w

# mkdirto.pl -- a simple utility to make a directory, if preceding directories
#               do not exist they are made prior.
#
# created for use with the penemo Makefile, by Nick Jennings.
#

use strict;

my $perm = $ARGV[0] || '';
my $dirto = $ARGV[1] || '';

unless (($perm) && ($dirto)) {
    print "Incorrect use of mkdirto.pl\n";
    print "Usage:\n";
    print "    mkdirto.pl <permissions> <full_path>\n";
    exit 1;
}

$dirto =~ s/^\///;
$dirto =~ s/\/$//;
my @each_dir = split('/', $dirto);
my $past = '/';

foreach my $dir (@each_dir) {
    print "checking for $past$dir... ";
    unless (-d "$past$dir") {
	print "creating... ";
        system("mkdir", "$past$dir");
	if ($?) {
	    print "failed!\n";
	    exit 2;
	}
	else {
            print "ok!\n";
	}
    }
    else {
        print "exists.\n";
    }
    $past .= "$dir/";
}

print "setting ownership ($perm) to $past... ";
system("chmod", $perm, $past);
if ($?) {
    print "failed!\n";
    exit 3;
}
else {
    print "ok!\n";
}

exit 0;
