#include <stdlib.h>
#include <maxi09os.h>

/* system io */

uint8_t ioerror = IO_ERR_OK;

DEVICE m_sysopen(char *name, uint8_t param2, uint8_t param1)
{
	DEVICE device;

#ifdef __GNUC__
	asm(
	"lda %1\n\t"
	"jsr [0xc008]\n\t"
	"stx %0\n\t"
	: "=m" (device) : "m" (param1) : "a"
	);
#else
	asm {
	pshs a,b
	ldx name
	lda param1
	ldb param2
	jsr [0xc008]
	stx device
	}
#endif

	return device;
}

void m_sysclose(DEVICE device)
{
#ifdef __GNUC__
	asm(
	"jsr [0xc00a]\n\t"
	);
#else
	asm {
	pshs x
	ldx device
	jsr [0xc00a]
	puls x
	}
#endif
}

uint8_t m_sysread(DEVICE device)
{
	uint8_t read_byte = 0;

#ifdef __GNUC__
	asm(
	"jsr [0xc00c]\n\t"
	"beq noerror\n\t" \
	"sta _ioerror\n\t" \
	"bra out\n\t" \
	"noerror:\n\t" \
	"sta %0\n\t" \
	"out:\n\t"
	: "=m" (read_byte) :
	);
#else
	asm {
	pshs x
	ldx device
	jsr [0xc00c]
	beq @noerror
	sta _ioerror
	bra @out
	@noerror:
	sta read_byte
	@out:
	puls x
	}
#endif
	return read_byte;
}

uint8_t m_syswrite(DEVICE device, uint8_t write_byte)
{
	uint8_t read_byte = 0;

#ifdef __GNUC__
	asm(
	"tfr b,a\n\t"
	"jsr [0xc00e]\n\t"
	"beq noerror\n\t" \
	"sta _ioerror\n\t" \
	"bra out\n\t" \
	"noerror:\n\t" \
	"sta %0\n\t" \
	"out:\n\t"
	: "=m" (read_byte) :
	);
#else
	asm {
	pshs x
	ldx device
	lda write_byte
	jsr [0xc00e]
	beq @noerror
	sta _ioerror
	bra @out
	@noerror:
	sta read_byte
	@out:
	puls x
	}
#endif
	return read_byte;
}

void m_sysseek(DEVICE device, uint16_t offset)
{
#ifdef __GNUC__
	asm(
	"ldy %0\n\t"
	"jsr [0xc010]\n\t"
	: : "m" (offset) : "y"
	);
#else
	asm {
	pshs x,y
	ldx device
	ldy offset
	jsr [0xc010]
	puls x,y
	}
#endif
}

void m_syscontrol(DEVICE device, uint8_t command, void *param)
{
#ifdef __GNUC__
	asm(
	"tfr b,a\n\t"
	"ldy %0\n\t"
	"jsr [0xc012]\n\t"
	: : "m" (param) : "y", "a"
	);
#else
	asm {
	pshs a,x,y
	ldx device
	lda command
	ldy param
	jsr [0xc012]
	puls a,x,y
	}
#endif
}


/* lib/io */

void m_putstrdefio(char *string)
{
#ifdef __GNUC__
	asm(
	"tfr x,y\n\t"
	"jsr [0xc060]\n\t"
	: : : "y"
	);
#else
	asm {
	pshs y
	ldy string
	jsr [0xc060]
	puls y
	}
#endif
}

void m_getstrdefio(char *string)
{
#ifdef __GNUC__
	asm(
	"tfr x,y\n\t"
	"jsr [0xc064]\n\t"
	: : : "y"
	);
#else
	asm {
	pshs y
	ldy string
	jsr [0xc064]
	puls y
	}
#endif
}

void m_getchars(DEVICE device, uint8_t *buffer, uint16_t count)
{
#ifdef __GNUC__
	asm(
	"ldy %0\n\t"
	"pshs u\n\t"
	"ldu %1\n\t"
	"jsr [0xc05e]\n\t"
	"puls u\n\t"
	: : "m" (buffer), "m" (count) : "y"
	);
#else
	asm {
	pshs x,y,u
	ldx device
	ldy buffer
	ldu count
	jsr [0xc05e]
	puls x,y,u
	}
#endif
}

/* memory */

uint8_t *m_memoryalloc(uint16_t size)
{
	uint8_t *ret;

#ifdef __GNUC__
	asm(
	"jsr [0xc034]\n\t"
	"stx %0\n\t"
	: "=m" (ret) : : "y"
	);
#else
	asm {
	ldx size
	jsr [0xc034]
	stx ret
	}
#endif

	return ret;
}

void m_memoryfree(uint8_t *memory)
{
#ifdef __GNUC__
	asm(
	"jsr [0xc036]\n\t"
	);
#else
	asm {
	pshs x
	ldx memory
	jsr [0xc036]
	puls x
	}
#endif
}

uint16_t m_memoryavail(uint8_t memoryflag)
{
	uint16_t ret;

#ifdef __GNUC__
	asm(
	"tfr b,a\n\t"
	"jsr [0xc032]\n\t"
	"std %0\n\t"
	: "=m" (ret) : : "a"
	);
#else
	asm {
	lda memoryflag
	jsr [0xc032]
	std ret
	}
#endif

	return ret;
}
