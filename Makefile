AS = as6809-wrapper -oxsw
FLASHER = tools/flasher

6809_SERIAL = /dev/ttyS0

BIN = main.bin

AREA_BASES = -b VECTORS=0xfff0 -b ROM=0xc000 -b DEBUGMSG=0xf800 -b RAM=0x0000

INCS = $(addprefix include/, ascii.inc debug.inc hardware.inc \
	minix.inc scancodes.inc system.inc v99lowlevel.inc)

MAIN_REL = main/main.rel

include $(addsuffix Makefile, drivers/ executive/ fs/ lib/ misc/ tasks/)

all: $(BIN)

main.bin: main.ihx
	hex2bin -out $@ $<

main.ihx: $(RELS) $(MAIN_REL)
	aslink $(AREA_BASES) -nmwi main.ihx $(MAIN_REL) $(RELS)

%.rel: %.asm $(INCS)
	$(AS) $@ $<

clean: $(CLEANDIRS)
	rm -f $(RELS) $(BIN) *.ihx *.map
	
flasher:
	$(FLASHER) -f $(BIN) -s $(6809_SERIAL)
