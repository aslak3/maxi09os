#!/usr/bin/perl
#
# STDIN->makevectors.pl VECTORFILE
#
# Output a vector table for ROM exported globals, using the existing vector
# asm file and a newly generated map,

use strict;
use warnings;

use Data::Dumper;

my $vectorfilename = $ARGV[0];

exit unless (defined $vectorfilename);

open(my $vectorfh, "+<", $vectorfilename) or die "Unable to open vector file: $!";

my %vectors;

# Skip the .area line.
my $dummy = <$vectorfh>;

while (<$vectorfh>)
{
	chomp;
	my ($global) = $_ =~ /^\s+.word (\w+)$/;
	if (defined $global) {
		$vectors{$global} = 1;
	}
}

# New vectors from the map file will go on the end of the file.

while (<STDIN>)
{
	chomp;
	my ($address, $global) = $_ =~ /^          ([\dA-Z]{4})  (\w+)/;
	if (defined $global)
	{
		$address = hex lc $address;
		# Ignore globals starting in underscore.
		next if ($global =~ /^_/);
		# Ignore globals in RAM.
		next if ($address < 0xc000);
		# Ignore vectors we've already put in the table
		next if (defined $vectors{$global});
		
		print $vectorfh "\t\t.word ${global}\n";
	}
}

close $vectorfh;
