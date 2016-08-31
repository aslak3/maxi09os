UPLOAD = $(HOME)/8bitcomputer/eepromprogrammer/upload/upload
FLASHER = ../6809/flasher/flasher

PROG_SERIAL = /dev/ttyUSB0
6809_SERIAL = /dev/ttyS0

BIN = main.bin
MAP = main.map
INC = main.inc

AREA_BASES = -b VECTORS=0xfff0 -b ROM=0xc000 -b RAM=0x0000

MAIN_REL = main.rel
RELS = memory.rel ticker.rel systemvars.rel strings.rel \
	tasks.rel testtasks.rel init.rel driver.rel io.rel uart.rel \
	debug.rel lists.rel led.rel timer.rel uartlowlevel.rel \
	console.rel scancodes.rel misc.rel

INCS = hardware.inc

all: $(BIN)

%.bin: %.ihx
	hex2bin -out $@ $<

%.ihx: $(MAIN_REL) $(RELS)
	aslink $(AREA_BASES) -nmwi $< $(MAIN_REL) $(RELS)
	
%.rel: %.asm
	as6809 -oxs $@ $<

externs.inc: *.asm
	for I in *.asm; do \
		echo "; $$I"; \
		echo; \
		for F in $$(cat $$I | grep :: | cut -d ":" -f 1); do \
			echo "\t\t.globl $$F"; \
		done; \
		echo; \
	 done \
	 > externs.inc

clean:
	rm -f $(BIN) $(INC) *.rel *.ihx *.map *.sym externs.inc

doupload:
	$(UPLOAD) -f $(BIN) -s $(PROG_SERIAL)

doflasher:
	$(FLASHER) -f $(BIN) -s $(6809_SERIAL)
	