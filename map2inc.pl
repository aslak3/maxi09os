#!/usr/bin/perl

use strict;
use warnings;

while (my $line = <>)
{
	my ($offset, $function) = $line =~ /([0-9A-F]{4})\s+((?!\d)\w+)/;

	if ($offset && $function) {
		print "$function .gblequ 0x$offset\n";
	}
}
