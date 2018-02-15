#include <termios.h>

int openserialport(char *portdevice, speed_t baud, int rtscts);
void closeserialport(int serialfd);
ssize_t myread(int fildes, void *buf, size_t nbyte);
ssize_t mywrite(int fildes, void *buf, size_t nbyte);
