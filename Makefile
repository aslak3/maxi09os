UPLOAD = $(HOME)/8bitcomputer/eepromprogrammer/upload/upload
FLASHER = ../6809/flasher/flasher

PROG_SERIAL = /dev/ttyUSB0
6809_SERIAL = /dev/ttyS0

BIN = main.bin

AREA_BASES = -b VECTORS=0xfff0 -b ROM=0xc000 -b DEBUGMSG=0xf800 -b RAM=0x0000

DIRS = drivers executive lib misc tasks

CLEANDIRS = $(addsuffix .clean, $(DIRS))

JOINEDS = $(addsuffix /all.rel, $(DIRS))

.PHONY: $(DIRS) $(CLEANDIRS)

all: $(BIN)

clean: $(CLEANDIRS)
	rm -f $(JOINEDS) $(BIN) $(INC) *.ihx *.map *.sym include/externs.inc
	
main.bin: main.ihx
	hex2bin -out $@ $<

main.ihx: $(DIRS)
	aslink $(AREA_BASES) -nmwi main.ihx $(JOINEDS)

$(DIRS):
	make -C $@

$(CLEANDIRS):
	make -C $(basename $@) clean

include/externs.inc:
	for I in $$(find -name "*.asm" | grep -v debug.asm); do \
		echo -n  "; " ; \
		echo $$I | cut -c 3- ; \
		echo; \
		for F in $$(cat $$I | grep :: | cut -d ":" -f 1); do \
			echo "\t\t.globl $$F"; \
		done; \
		echo; \
	 done \
	 > $@


doupload:
	$(UPLOAD) -f $(BIN) -s $(PROG_SERIAL)

doflasher:
	$(FLASHER) -f $(BIN) -s $(6809_SERIAL)
