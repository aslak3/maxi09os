AS = ../tools/as6809-wrapper -oxlsw

BIN = test.bin gettime.bin settime.bin

INCS = ../include/hardware.inc

all: $(BIN)

%.bin: %.ihx
	objcopy -I ihex $< -O binary $@

%.ihx: %.rel
	aslink -nmwi $@ $<
	
%.rel: %.asm
	$(AS) $@ $<

clean:
	rm -f $(BIN) *.rel *.ihx *.map *.sym
