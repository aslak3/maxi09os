AS = ../tools/as6809-wrapper -oxsw

BIN = test.bin

TEST_ASM = test.asm

INCS = ../include/hardware.inc

all: $(BIN)

%.bin: %.ihx
	hex2bin -out $@ $<

%.ihx: %.rel
	aslink -nmwi $@ $<
	
%.rel: $(TEST_ASM) $(INCS)
	$(AS) $@ $<

clean:
	rm -f $(BIN) *.rel *.ihx *.map *.sym
