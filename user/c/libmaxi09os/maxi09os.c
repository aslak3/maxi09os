#include <stdlib.h>
#include <maxi09os.h>

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

uint8_t *m_memoryalloc(uint16_t size)
{
	uint8_t *ret;
	asm(
	"jsr [0xc034]\n\t"
	"stx %0\n\t"
	: "=m" (ret) : : "y"
	);
	return ret;
}

void m_memoryfree(uint8_t *memory)
{
	asm(
	"jsr [0xc036]\n\t"
	);
}

uint16_t m_memoryavail(uint8_t memoryflag)
{
	uint16_t ret;
	asm(
	"tfr b,a\n\t"
	"jsr [0xc032]\n\t"
	"std %0\n\t"
	: "=m" (ret) : : "y"
	);
	return ret;
}
