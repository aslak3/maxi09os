AS = as6809-wrapper -oxsw
FLASHER = ../tools/flasher
BIN2MIF = ../tools/bin2mif.pl

MIF = loader.mif
BIN = loader.bin

LOADER_ASM = loader.asm

INCS = ../include/hardware.inc

all: $(MIF)

%.mif: %.bin
	$(BIN2MIF) < $< > $@

%.bin: %.ihx
	hex2bin -out $@ $<

%.ihx: %.rel
	aslink -nmwi $@ $<
	
%.rel: $(LOADER_ASM) $(INCS)
	$(AS) -oxs $<

clean:
	rm -f $(MIF) $(BIN) *.rel *.ihx *.map *.sym
