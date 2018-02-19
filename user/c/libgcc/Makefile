include ../Makefile.inc

ARFLAGS = -r

OBJS = divmodhi3.o

all : libgcc.a

libgcc.a : $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

%.o : %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(OBJS) *.a
