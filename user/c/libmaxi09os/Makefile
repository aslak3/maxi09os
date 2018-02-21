include ../Makefile.inc

ARFLAGS = -r

OBJS = maxi09os.o

all : libmaxi09os.a

libmaxi09os.a : $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

clean:
	rm -f $(OBJS) *.a
