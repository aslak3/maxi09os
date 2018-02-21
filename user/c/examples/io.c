#include <maxi09os.h>

int main(void)
{
	char buffer[100];
	m_putstrdefio("What is your name? ");
	m_getstrdefio(buffer);

	m_putstrdefio("Hello ");
	m_putstrdefio(buffer);
	m_putstrdefio("\r\n");

	return 0;
}
