include ../Makefile.inc

ARFLAGS = -r

OBJS = divmodhi3.o

all : libgcc.a

libgcc.a : $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

clean:
	rm -f $(OBJS) *.a
