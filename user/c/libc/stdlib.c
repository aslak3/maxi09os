#include "ctype.h"

int atoi(const char* str)
{
	int val = 0;
	int neg = 0;

	while(isspace(*str))
	{
		str++;
	}

	switch(*str)
	{
		case '-':
			neg = 1;
		// intentional fallthrough
		case '+':
			str++;
	}

	while(isdigit(*str))
	{
		val = (10 * val) + (*str++ - '0');
	}

	return neg ? -val : val;
}
