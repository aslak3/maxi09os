#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <termios.h>
#include <fcntl.h>

int openserialport(char *portdevice, speed_t baud, int rtscts)
{
	int serialfd = open(portdevice, O_RDWR | O_NOCTTY | O_NDELAY);
	if (serialfd < 0)
		return -1;

	fcntl(serialfd, F_SETFL, 0);

	struct termios options;
	
	memset(&options, 0, sizeof(struct termios));

	options.c_cflag = CS8 | CLOCAL | CREAD | (rtscts ? CRTSCTS : 0); /* 8n1, local, enable reading */
	options.c_iflag = IGNPAR; /* ignore bytes with parity */
	options.c_oflag = 0;
	options.c_lflag = 0; /* non-canocial mode */
	options.c_cc[VTIME] = 0; /* inter-character timer unused */
	options.c_cc[VMIN] = 1; /* blocking read until 1 character arrives */

	cfsetispeed(&options, baud);
	cfsetospeed(&options, baud);
	
	tcflush(serialfd, TCIFLUSH);
	tcsetattr(serialfd, TCSANOW, &options);

	return serialfd;
}

void closeserialport(int serialfd)
{
	close(serialfd);
}

ssize_t myread(int fildes, void *buf, size_t nbyte)
{
	ssize_t c = 0;
	while (c < nbyte)
	{
		ssize_t t;
		if ((t = read(fildes, buf + c, nbyte - c)) < 0)
			return t;
		c += t;
	}
	return c;
}

ssize_t mywrite(int fildes, void *buf, size_t nbyte)
{
	ssize_t c = 0;
	while (c < nbyte)
	{
		ssize_t t;
		if ((t = write(fildes, buf + c, nbyte - c)) < 0)
			return t;
		c += t;
	}
	return c;
}
