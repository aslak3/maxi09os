#include <stdio.h>

#include <maxi09os.h>
#include <hardware.h>

char *daynames[7] = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" };

int main(void)
{
	DEVICE rtc = m_sysopen("spi", 0, SPICLOCK);
	if (!rtc)
	{
		m_putstrdefio("Can't open RTC\r\n");
		return 1;
	}

	/* Read from address 0 */
	m_syswrite(rtc, 0);

	uint8_t spidata[7];
	char outputbuffer[40];

	/* We need 7 bytes */
	m_getchars(rtc, spidata, 7);

	m_sysclose(rtc);

	snprintf(outputbuffer, 40, "%02x:%02x:%02x %s %02x/%02x/%02x\r\n",
		spidata[2], spidata[1], spidata[0],
		daynames[spidata[3] - 1],
		spidata[4], spidata[5], spidata[6]
	);
	m_putstrdefio(outputbuffer);

	return 0;
}
