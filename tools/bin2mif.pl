#!/usr/bin/perl
#
# Convert a 256 binary file to Altera Memory Image Format.
# See: https://www.mil.ufl.edu/4712/docs/mif_help.pdf
#
# STDIN->bin2mif.pl->STDOUT

my $offset = 0;
my $hcar;

print "DEPTH = 256;\n";
print "WIDTH = 8;\n";
print "ADDRESS_RADIX = DEC;\n";
print "DATA_RADIX = HEX;\n";
print "\n";
print "CONTENT\n";
print "BEGIN\n";

while (sysread(STDIN, $char, 1))
{
	if (($offset % 16) == 0) {
		print $offset . "\t:";
	}
	print ' ' . sprintf("%02x", ord($char));
	if (($offset % 16) == 15) {
		print ";\n";
	}
	$offset++;
}
print "END;\n";
