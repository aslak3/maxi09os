#!/usr/bin/perl
#
# STDIN->maptoequates.pl->STDOUT

while (<>)
{
	chomp;
	my ($address, $global) = $_ =~ /^          ([\dA-Z]{4})  (\w+)/;
	if (defined $global)
	{
		$address = lc $address;

		my $tabs = "\t";
		if (length $global < 8) {
			$tabs = "\t\t";
		}
	
		print "${global}${tabs}.equ 0x${address}\n";
	}
}
