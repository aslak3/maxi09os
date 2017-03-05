export PATH := $(shell pwd)/../tools:$(PATH)

MIF = bootloader.mif
BIN = bootloader.bin

LOADER_ASM = bootloader.asm

INCS = ../include/hardware.inc

all: $(MIF)

%.mif: %.bin
	bin2mif.pl < $< > $@

%.bin: %.ihx
	hex2bin -out $@ $<

%.ihx: %.rel
	aslink -nmwi $@ $<
	
%.rel: $(LOADER_ASM) $(INCS)
	as6809 -oxs $<

clean:
	rm -f $(MIF) $(BIN) *.rel *.ihx *.map *.sym
