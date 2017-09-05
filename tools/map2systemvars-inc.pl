#!/usr/bin/perl
#
# STDIN->map2equates.pl->STDOUT
#
# Output equates for all globals in RAM.

while (<>)
{
	chomp;
	my ($address, $global) = $_ =~ /^          ([\dA-Z]{4})  (\w+)/;
	if (defined $global)
	{
		$address = hex lc $address;

		# Ignore globals starting in underscore.
		next if ($global =~ /^_/);
		# Ignore globals in ROM.
		next if ($address >= 0xc000);

		# Try to align the text nicely.
		my $tabs = "\t";
		if (length $global < 8) {
			$tabs = "\t\t";
		}
	
		# Print out the equate line.
		printf "%s%s .equ 0x%04x\n", $global, $tabs, $address;
	}
}
