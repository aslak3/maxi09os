include ../Makefile.inc

ARFLAGS = -r

OBJS = ctype.o string.o stdlib.o mini-printf.o

all : libc.a

libc.a : $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

clean:
	rm -f $(OBJS) *.a
