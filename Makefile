AS = tools/as6809-wrapper -oxlsw

6809_SERIAL = /dev/ttyS0

BIN = main.bin

AREA_BASES = -b VECTORS=0xfff0 -b ROM=0xc000 -b DEBUGMSG=0xf800 -b RAM=0x0000

INCS = $(addprefix include/, ascii.inc debug.inc hardware.inc \
	minix.inc scancodes.inc system.inc v99lowlevel.inc)

MAIN_REL = main/main.rel

AUTOGEN-INC = include/autogen.inc

include $(addsuffix Makefile, drivers/ executive/ fs/ lib/ misc/ tasks/)

all: $(BIN) include/autogen.inc

$(BIN): main.ihx
	hex2bin -out $@ $<

main.ihx: $(RELS) $(MAIN_REL)
	aslink $(AREA_BASES) -onmuwi main.ihx $(MAIN_REL) $(RELS)

%.rel: %.asm $(INCS)
	$(AS) $@ $<

clean: $(CLEANDIRS)
	rm -f $(MAIN_REL) $(RELS) $(BIN) *.ihx *.map
	
flasher:
	tools/flasher -f $(BIN) -s $(6809_SERIAL)

$(AUTOGEN-INC): $(BIN)
	tools/map2equates.pl < main.map > $(AUTOGEN-INC)
