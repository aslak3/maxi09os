CC = m6809-unknown-gcc
AR = m6809-unknown-ar

CFLAGS = -Wall -std=gnu99 -fPIC
ARFLAGS = -r

OBJS = divmodhi3.o

all : libgcc.a

libgcc.a : $(OBJS)
	$(AR) $(ARFLAGS) $@ $(OBJS)

%.o : %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f $(OBJS) *.a
