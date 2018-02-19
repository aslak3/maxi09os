void m_putstr(char *string)
{
	asm(
	"tfr x,y\n\t"
	"jsr [0xc060]\n\t"
	: :  : "y"
	);
}

void m_getstr(char *string)
{
	asm(
	"tfr x,y\n\t"
	"jsr [0xc064]\n\t"
	: : : "y"
	);
}

//memoryavail      .equ 0xc032
//memoryalloc      .equ 0xc034
//memoryfree       .equ 0xc036
