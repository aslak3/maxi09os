#include <maxi09os.h>

int main(void)
{
	char buffer[100];
	m_putstr("What is your name? ");
	m_getstr(buffer);

	m_putstr("Hello ");
	m_putstr(buffer);
	m_putstr("\r\n");
}
