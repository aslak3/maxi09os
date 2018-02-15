#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>

#include <sys/stat.h>

#include "serialio.h"

#define REPLY_SIZE 256

void stripnl(char *s);
int flashfile(int serialfd, char *filename);
int waitfornewline(int serialfd);
void usage(char *argv0);

int main(int argc, char *argv[])
{
	char *argv0 = argv[0];
	char *serialport = "/dev/ttyS0";
	char *filename = NULL;
	int c;
	
	while ((c = getopt(argc, argv, "hs:f:r:o:")) != -1)
	{
		switch(c)
		{
			case 'h':
				usage(argv[0]);
				break;
			case 's':
				serialport = optarg;
				break;
			case 'f':
				filename = optarg;
				break;
			default:
				abort();
		}
	}

	int serialfd = openserialport(serialport, B9600, 0);
	if (!serialfd)
	{
		perror("Unable to open serial port");
		exit(1);
	}
	
	if (filename)
		flashfile(serialfd, filename);
	else
	{
		fprintf(stderr, "No filename specified\n");
		usage(argv0);
	}
	
	closeserialport(serialfd);
	
	return (0);
}

void stripnl(char *s)
{
	char *t = s;

	while (*t != '\r' && *t != '\n') t++;
	*t = '\0';
}

int flashfile(int serialfd, char *filename)
{
	int filefd = open(filename, O_RDONLY);
	if (filefd < 0)
	{
		perror("Unable to open input file");
		return 1;
	}
	
	struct stat statbuf;
	fstat(filefd, &statbuf);
	off_t filesize = statbuf.st_size;
	
	printf("File is %ld bytes\n", filesize);
	
	if (filesize != (off_t) 16384)
	{
		fprintf(stderr, "File not 16KB\n");
		return 1;
	}

	if (waitfornewline(serialfd) < 0)
	{
		perror("Error waiting for newline");
		return 1;
	}
	if (waitfornewline(serialfd) < 0)
	{
		perror("Error waiting for newline");
		return 1;
	}

	if (mywrite(serialfd, "f", 1) != 1)
	{
		perror("Error writing 'f'");
		return 1;
	}

	char gomarker[4];
	memset(gomarker, 0, 4);
	
	printf("Waiting for go signal\n");
	
	if (myread(serialfd, gomarker, 3) < 1)
	{
		perror("Unable to read serial when waiting for +++");
		return 1;
	}

	if (strcmp(gomarker, "+++") != 0)
	{
		fprintf(stderr, "Did not get go signal to start flashing [%s]\n", gomarker);
		return 1;
	}
	
	printf("Writing...\n");

	off_t bytessent = 0;
	unsigned char transmissionbuffer[64];

	while (bytessent < filesize)
	{
		int bytesread;
		unsigned char hashbyte;

		memset(transmissionbuffer, 0, 64);
		if ((bytesread = myread(filefd, transmissionbuffer, 64)) < 0)
		{
			perror("Unable to read from input file");
			return 1;
		}
		mywrite(serialfd, transmissionbuffer, 64);

		if (myread(serialfd, &hashbyte, 1) < 1)
		{
			perror("Unable to read serial when waiting for block");
			return 1;
		}

		bytessent += bytesread;
		printf("#");
		fflush(stdout);
	}
	
	printf("\n=== Sent %ld bytes ===\n", bytessent);
	printf("Validating...\n");

	/* Move input file FD back to the start. */
	lseek(filefd, 0, SEEK_SET);
	
	off_t bytesvalidated = 0;
	while (bytesvalidated < filesize)
	{
		unsigned char filebyte;
		unsigned char memorybyte;
		
		if (myread(serialfd, &memorybyte, 1) < 1)
		{
			perror("Unable to read serial when validating");
			return 1;
		}
		
		if (myread(filefd, &filebyte, 1) < 1)
		{
			perror("Unable to read file when validating");
			return 1;
		}
		
		if (memorybyte != filebyte)
		{
			printf("\n");
			fprintf(stderr, "Error validating at byte %ld (%04lx), should be %02x but got %02x\n",
				bytesvalidated, bytesvalidated, filebyte, memorybyte);
			return 1;
		}
		
		bytesvalidated++;
		
		if (!(bytesvalidated % 64))
		{
			printf("#");
			fflush(stdout);
		}
	}
	if (bytesvalidated % 64)
		printf("#");

	printf("\n=== No errors ===\n");
	
	if (filefd > -1)
		close(filefd);

	return 0;
}

int waitfornewline(int serialfd)
{
	char buffer;
	
	while (myread(serialfd, &buffer, 1) > 0)
	{
		if (buffer == '\n')
			return 0;
	}
	
	return -1;
}

void usage(char *argv0)
{
	fprintf(stderr, "Usage: %s -f filename [-s serialport]\n" \
		"\tserialport defaults to /dev/ttyS0\n", argv0);
	exit(1);
}
