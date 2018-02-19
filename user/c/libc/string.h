#ifdef __STRING_H__
#define __STRING_H__

#include <stdlib.h>

void *memcpy(void *dest, const void *src, int n);
void *memset(void *s, int c, int n);

size_t strlen(const char *s);

#endif
