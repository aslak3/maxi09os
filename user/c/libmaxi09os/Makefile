include ../Makefile.inc

ARFLAGS = -r

OBJS = maxi09os.o

all : libmaxi09os.a

libmaxi09os.a : $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

%.o : %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(OBJS) *.a
