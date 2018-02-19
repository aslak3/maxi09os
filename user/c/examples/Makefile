CC = m6809-unknown-gcc
LD = m6809-unknown-ld

CFLAGS = -O0 -Wall -std=gnu99 -fPIC -I../libc/
LDFLAGS = -T linkerscript -nostdlib -L../libc -L../libgcc -lc -lgcc

all : prime.bin easter.bin io.bin

%.bin : %.o ../libc/libc.a ../libgcc/libgcc.a
	$(LD) $(LDFLAGS) -o $@ $<

%.o : %.c
	$(CC) $(CFLAGS) -c $<

clean:
	rm -f *.o *.bin
