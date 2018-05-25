include ../Makefile.inc

ifeq ($(TOOLCHAIN), gcc)
LDFLAGS = -T linkerscript-gcc -nostdlib -L../libgcc -L../libc -L../libmaxi09os \
	-lgcc -lc -lmaxi09os
else ifeq ($(TOOLCHAIN), cmoc)
ifeq ($(LD), lwlink)
LDFLAGS = -r -s linkerscript-lwlink -L/usr/share/cmoc/lib -L../libc -L../libmaxi09os \
	-lcmoc-std-ecb -lc -lmaxi09os
else
LDFLAGS = -nodefaultlibs --srec -L../libc -L../libmaxi09os
LIBS = -lcmoc-std-ecb -lc -lmaxi09os
endif
endif
#-lcmoc-crt-ecb -L/usr/share/cmoc/lib
all : prime.bin easter.bin io.bin avail.bin gettime.bin joystick.bin

%.bin : %.o ../libc/libc.a ../libgcc/libgcc.a ../libmaxi09os/libmaxi09os.a
ifeq ($(LD), cmoc)
	$(LD) $(LDFLAGS) -o $(patsubst %.bin,%.srec,$@) $< $(LIBS)
	objcopy -I srec -O binary $(patsubst %.bin,%.srec,$@) $@
	rm $(patsubst %.bin,%.srec,$@)
else
	$(LD) $(LDFLAGS) -o $@ $<
endif

clean:
	rm -f *.o *.bin
