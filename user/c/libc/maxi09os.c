void m_putstr(char *string)
{
	asm(
	"ldy %[in]\n\t"
	"jsr [0xc060]\n\t"
	: : [in] "" (string) : "y"
	);
}

void m_getstr(char *string)
{
	asm(
	"ldy %[in]\n\t"
	"jsr [0xc064]\n\t"
	: : [in] "" (string) : "y"
	);
}

//memoryavail      .equ 0xc032
//memoryalloc      .equ 0xc034
//memoryfree       .equ 0xc036
