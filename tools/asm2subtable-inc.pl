#!/usr/bin/perl
#
# STDIN->asm2subtable.pl->STDOUT
#
# Output equates for all .words in asm file, starting from 0xc000.

my $address = 0xc000;

while (<>)
{
	chomp;
	my ($global) = $_ =~ /^\s+.word (\w+)/;
	if (defined $global)
	{
		# Try to align the text nicely.
		my $tabs = "\t";
		if (length $global < 8) {
			$tabs = "\t\t";
		}
	
		# Print out the equate line.
		printf "%s%s .equ 0x%04x\n", $global, $tabs, $address;

		$address += 2;
	}
}
