include ../Makefile.inc

LDFLAGS = -T linkerscript -nostdlib -L../libc -L../libgcc -L../libmaxi09os \
	-lc -lgcc -lmaxi09os

all : prime.bin easter.bin io.bin avail.bin

%.bin : %.o ../libc/libc.a ../libgcc/libgcc.a
	$(LD) $(LDFLAGS) -o $@ $<

%.o : %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f *.o *.bin
