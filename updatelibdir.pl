#!/usr/bin/perl -w

# updatelibdir.pl -- a simple utility to update the use lib in the penemo
#                    libraries, to the place where they will be installed.
#
# created for use with the penemo Makefile, by Nick Jennings.
#

use strict;

my $libdir = $ARGV[0] || '';
my $moddir = $ARGV[1] || ''; # directory in which to begin search and replace

unless (($libdir) && ($moddir)) {
    print "Incorrect use of updatelibdir.pl\n";
    print "Usage:\n";
    print "    updatelibdir.pl <full_path_to_libdir> <path_to_modfiles>\n";
    exit 1;
}

#$libdir =~ s/^\///;
$libdir =~ s/\/$//;

sub traverse_tree($) {
	my $dir = shift;
	print "Processing dir $dir...\n";
	opendir(D, $dir);
	foreach my $entry (readdir(D)) {
		next if ($entry =~ /^\./); # skip dot files

		if (-d "$dir/$entry") {
			traverse_tree("$dir/$entry");
		}
		elsif (-f "$dir/$entry") {
			parse_file("$dir/$entry");
		}
		else {
			print "Unable to determin type for $dir/$entry\n";
		}
	}
	close(D);
}

sub parse_file($) {
	my $file = shift;
	print "Processing file $file...\n";
	system('cp', $file, "$file.tmp");
	open(OF, "<$file.tmp") or die "Unable to open file '$file.tmp' : $!\n"; 
	open(NF, ">$file") or die "Unable to open file '$file' : $!\n"; 
	foreach my $line (<OF>) {
		if ($line =~ /\s*use lib/) {
			print "** Found entry in $file **\n";
			print "$line\n";
			print NF "use lib '$libdir';\n";
		}
		else {
			print NF $line;
		}
	}
	close(OF);
	close(NF);
	system('rm', "$file.tmp");
}

&traverse_tree($moddir);

exit 0;
