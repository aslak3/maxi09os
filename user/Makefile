AS = ../tools/as6809-wrapper -oxsw

BIN = test.bin gettime.bin settime.bin

INCS = ../include/hardware.inc

all: $(BIN)

%.bin: %.ihx
	hex2bin -out $@ $<

%.ihx: %.rel
	aslink -nmwi $@ $<
	
%.rel: %.asm
	$(AS) $@ $<

clean:
	rm -f $(BIN) *.rel *.ihx *.map *.sym
