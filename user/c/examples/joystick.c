#include <stdio.h>

#include <maxi09os.h>
#include <hardware.h>

uint8_t getpos(DEVICE joy, int yflag);

int main(void)
{
	char outputbuffer[40];

	DEVICE joy = m_sysopen("spi", 0, SPIANALOGJOY0);
	if (!joy)
	{
		m_putstrdefio("Can't open joystick\r\n");
		return 1;
	}

	for (int c = 0; c < 2000; c++)
	{
		unsigned char posx = getpos(joy, 0);
		unsigned char posy = getpos(joy, 1);
		
		snprintf(outputbuffer, 40, "x = %u y = %u\r\n",
			posx, posy
		);

		m_putstrdefio(outputbuffer);
	}
	
	m_sysclose(joy);

	return 0;
}

/* Return the position of the joystick as a value from 0 to 255, where
 * 128 is (roughly) where the joystick is centered. */
uint8_t getpos(DEVICE joy, int yflag)
{
	uint8_t spidata[2];

	/* Send the command to get the value *and* get the high two bits
	 * of the result. This is the only time where syswrite returns
	 * a value. */
	spidata[0] = m_syswrite(joy, 0x60 | (yflag ? 0x00 : 0x10));
	/* Read out the low 8 bits of the 10 bit value. */
	spidata[1] = m_sysread(joy);

	/* Flip open again so we can get the next reading. */
	m_syscontrol(joy, 0, 0);

	/* Squish the 10 bit value spread over two bytes into an 8 bit
	 * byte, discarding the low 2 bits from the 10. */
	return ((spidata[0] << 6) | (spidata[1] >> 2));
}
