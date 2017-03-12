export PATH := $(shell pwd)/tools:$(PATH)

FLASHER = flasher

6809_SERIAL = /dev/ttyS0

BIN = main.bin

AREA_BASES = -b VECTORS=0xfff0 -b ROM=0xc000 -b DEBUGMSG=0xf800 -b RAM=0x0000

DIRS = main drivers executive lib misc tasks fs

CLEANDIRS = $(addsuffix .clean, $(DIRS))
DIRSALL = $(addsuffix /all.rel, $(DIRS))

.PHONY: $(DIRS) $(CLEANDIRS)

all: $(BIN)

clean: $(CLEANDIRS)
	rm -f $(DIRSALL) $(BIN) *.ihx *.map *.sym include/externs.inc
	
main.bin: main.ihx
	hex2bin -out $@ $<

main.ihx: $(DIRSALL)
	aslink $(AREA_BASES) -nmwi main.ihx $(DIRSALL)

$(DIRSALL): $(DIRS)
	make -C $(dir $@)

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

flasher:
	$(FLASHER) -f $(BIN) -s $(6809_SERIAL)
