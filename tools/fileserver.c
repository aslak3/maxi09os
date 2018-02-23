/* Simple serial file server. */

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <stdlib.h>
#include <fcntl.h>
#include <stdint.h>

#include <arpa/inet.h>

#include <sys/stat.h>
#include <sys/ioctl.h>

#include "serialio.h"

#define BUFFER_SIZE 256

/* All integer quantities on the wire are 16 bit, all enumerated values
 * are bytes. */

/* Commands: */

#define COM_NULL 0		/* Does nothing. */
#define COM_GET 1		/* Filename\0. */
#define COM_SIZE 2		/* Filename\0. */

/* Rplies: */

#define REP_NULL 0		/* Empty. */
#define REP_GET_DATA 1		/* Size, data. */
#define REP_NOT_FOUND 2		/* Empty. */
#define REP_BAD_COMMAND 3	/* Empty. */
#define REP_TOO_BIG 4		/* Empty. */

uint16_t readword(int fd);
void writeword(int fd, uint16_t word);
uint8_t readbyte(int fd);
void writebyte(int fd, uint8_t byte);
int mainloop(int serialfd);
int handlenull(int serialfd);
int handleget(int serialfd);
void usage(char *argv0);

int main(int argc, char *argv[])
{
	char *serialport = "/dev/ttyS0";
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
			default:
				abort();
		}
	}

	int serialfd = openserialport(serialport, B19200, 0);
	if (!serialfd)
	{
		perror("Unable to open serial port");
		exit(1);
	}
	
	mainloop(serialfd);
	
	closeserialport(serialfd);
	
	return (0);
}

uint16_t readword(int fd)
{
	uint16_t word;
	
	/* Read the word. */
	if ((myread(fd, &word, 2)) < 0)
	{
		perror("Unable to read");
	}

	/* Big-endian flip. */
	return htons(word);
}

void writeword(int fd, uint16_t word)
{
	int byteswritten;
	uint16_t wordswapped = htons(word);
	
	/* Write the word. */
	if ((byteswritten = mywrite(fd, &wordswapped, 2)) < 0)
	{
		perror("Unable to write");
	}
}

uint8_t readbyte(int fd)
{
	uint8_t byte;
	
	/* Read the byte. */
	if ((myread(fd, &byte, 1)) < 0)
	{
		perror("Unable to read");
	}

	return byte;
}

void writebyte(int fd, uint8_t byte)
{
	int byteswritten;

	/* Write the byte. */
	if ((byteswritten = mywrite(fd, &byte, 1)) < 0)
	{
		perror("Unable to write");
	}
}

int mainloop(int serialfd)
{
	while (1)
	{
		uint8_t commandbyte;
		
		printf("\nReady for next command\n");
		
		commandbyte = readbyte(serialfd);
		
		printf("Get commandbyte: %d\n", commandbyte);

		switch (commandbyte)
		{
			case COM_NULL:
				handlenull(serialfd);
				break;
			case COM_GET:
				handleget(serialfd);
				break;
			default:
				break;
		}
	}
}

int handlenull(int serialfd)
{
	printf("Null command\n");

	writeword(serialfd, REP_NULL);
	
	return 0;
}

int handleget(int serialfd)
{
	printf("Get command\n");

	char filename[BUFFER_SIZE];
	int filenamecount = 0;

	while (filenamecount < BUFFER_SIZE)
	{
		uint8_t byte = readbyte(serialfd);
		filename[filenamecount++] = byte;
		if (!byte)
			break;
	}
	
	printf("Filename requeted: %s\n", filename);

	int filefd = open(filename, O_RDONLY);
	if (filefd < 0)
	{
		perror("Unable to open input file");
		writebyte(serialfd, REP_NOT_FOUND);
		return 1;
	}
	
	struct stat statbuf;
	fstat(filefd, &statbuf);
	off_t filesize = statbuf.st_size;
	
	printf("File is %ld bytes\n", filesize);
	
	if (filesize > 65535)
	{
		fprintf(stderr, "File >64KB\n");
		writebyte(serialfd, REP_TOO_BIG);
		return 1;
	}

	writebyte(serialfd, REP_GET_DATA);

	uint16_t filesizeword = (uint16_t) filesize;
	writeword(serialfd, filesizeword);

	printf("Writing...\n");

	int bytesinblock;
	int bytessent = 0;

	while (bytessent < filesize)
	{
		/* Any byte will do. */
//		printf("[");
//		readbyte(serialfd);
		
		for (bytesinblock = 0;
			bytesinblock < 256 && bytessent < filesize;
			bytesinblock++)
		{
			uint8_t filebyte = readbyte(filefd);
			writebyte(serialfd, filebyte);

			bytessent++;
			
			printf(".");
			fflush(stdout);
		}

//		printf("]\n");
//		fflush(stdout);
	}
	
	if (filefd > -1)
		close(filefd);

	return 0;
}

void usage(char *argv0)
{
	fprintf(stderr, "Usage: %s [-s serialport]\n" \
		"\tserialport defaults to /dev/ttyS0\n", argv0);
	exit(1);
}
