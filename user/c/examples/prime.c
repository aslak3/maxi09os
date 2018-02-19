#include <stdio.h>
#include <stdlib.h>

#include <maxi09os.h>

int main(void)
{
	char buffer[100];
	int test, max;

	m_putstr("Enter the highest integer to test: ");
	m_getstr(buffer);
	max = atoi(buffer);

	if (max < 2)
	{
		m_putstr("Number must be greater then 1\r\n");
		return 1;
	}

	for (test = 2; test <= max; test++)
	{
		int check, flag = 0;

		for (check = 2; check <= test / 2; check++)
		{
			if (!(test % check))
			{
				flag = 1;
				break;
			}
		}

		if (flag == 0)
		{
			snprintf(buffer, 100, "%d is a prime number.\r\n", test);
			m_putstr(buffer);
		}
	}

	m_putstr("Done\r\n");
	
	return 0;
}
