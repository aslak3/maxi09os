#ifndef __MAXI09OS_H__
#define __MAXI09OS_H__

#include <stdlib.h>

#ifdef __GNUC__
int main(void)  __attribute__ ((section ("main")));
#endif

/* low level io */

#define IO_ERR_OK 0		/* io operation completed ok */
#define IO_ERR_WAIT 1		/* task should wait, no data yet */
#define IO_ERR_EOF 2		/* end of file reached */
#define IO_ERR_BREAK 0xff	/* get a break signal */

typedef void *DEVICE;

DEVICE m_sysopen(char *name, uint8_t param1, uint8_t param2);
void m_sysclose(DEVICE device);
uint8_t m_sysread(DEVICE device);
uint8_t m_syswrite(DEVICE device, uint8_t byte);
void m_sysseek(DEVICE device, uint16_t offset);
void m_syscontrol(DEVICE device, uint8_t command, void *param);

/* lib io */

void m_putstrdefio(char *string);
void m_getstrdefio(char *string);
void m_getchars(DEVICE device, uint8_t *buffer, uint16_t count);

/* memory */

#define AVAIL_TOTAL 0
#define AVAIL_FREE 1
#define AVAIL_LARGEST 2

uint8_t *m_memoryalloc(uint16_t size);
void m_memoryfree(uint8_t *memory);
uint16_t m_memoryavail(uint8_t memoryflag);

#endif
