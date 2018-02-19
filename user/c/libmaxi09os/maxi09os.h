#ifndef __MAXI09OS_H__
#define __MAXI09OS_H__

#include <stdlib.h>

#ifdef __GNUC__
int main(void)  __attribute__ ((section ("main")));
#endif

/* io */

void m_putstr(char *string);
void m_getstr(char *string);

/* memory */

#define AVAIL_TOTAL 0
#define AVAIL_FREE 1
#define AVAIL_LARGEST 2

uint8_t *m_memoryalloc(uint16_t size);
void m_memoryfree(uint8_t *memory);
uint16_t m_memoryavail(uint8_t memoryflag);

#endif
