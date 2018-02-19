include ../Makefile.inc

ARFLAGS = -r

OBJS = ctype.o string.o stdlib.o maxi09os.o mini-printf.o

all : libc.a

libc.a : $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

%.o : %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(OBJS) *.a
