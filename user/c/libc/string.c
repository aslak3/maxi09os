#include "stdlib.h"

void *memcpy(void *dest, const void *src, int n)
{
	for (int c = 0; c < n; c++)
	{
		((char *)dest)[c] = ((char *)src)[c];
	}
	return dest;
}

void *memset(void *s, int c, int n)
{
	char *p = (char *) s;
	for (int x = 0; x < c; x++)
	{
		for (int y = 0; y < n; y++)
		{
			*p++ = '\0';
		}
	}
		
	return s;
}

size_t strlen(const char *s)
{
	char *news = (char *) s;
	
	while (*(news++));
	
	return news - s;
}
