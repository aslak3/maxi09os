#!/usr/bin/perl

use strict;
use warnings;

my $asmfilename = $ARGV[0];
my $relfilename = $ARGV[1];

if (not defined $relfilename)
{
	exit 1;
}

open(my $fh, "<", $asmfilename) or die "Unable to open $asmfilename: $!";

print $relfilename . ": " . $asmfilename . " ";

while (<$fh>)
{
	if (m/\.include \'(.*)'/) {
		print $1 . " ";
	}
}

print "\n";

close $fh;
