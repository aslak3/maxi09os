#include <stdio.h>
#include <stdlib.h>

#include <maxi09os.h>

#define BUFFER_SIZE 100

int main(void)
{
	uint16_t memcount;
	char buffer[BUFFER_SIZE];
	
	memcount = m_memoryavail(AVAIL_TOTAL);
	snprintf(buffer, BUFFER_SIZE, "Total: %u\r\n", memcount);
	m_putstrdefio(buffer);

	memcount = m_memoryavail(AVAIL_FREE);
	snprintf(buffer, BUFFER_SIZE, "Free: %u\r\n", memcount);
	m_putstrdefio(buffer);

	memcount = m_memoryavail(AVAIL_LARGEST);
	snprintf(buffer, BUFFER_SIZE, "Largest: %u\r\n", memcount);
	m_putstrdefio(buffer);

	return 0;
}
