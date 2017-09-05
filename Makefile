AS = tools/as6809-wrapper -oxlsw

6809_SERIAL = /dev/ttyS0

BIN = main.bin

AREA_BASES = -b VECTORS=0xfff0 -b ROM=0xc000 -b DEBUGMSG=0xf800 -b RAM=0x0000

INCS = $(addprefix include/, ascii.inc debug.inc hardware.inc \
	minix.inc scancodes.inc system.inc v99lowlevel.inc)

SYSTEMVARS_REL = main/systemvars.rel
SUBTABLE_REL = main/subtable.rel

SYSTEMVARS_INC = user/include/systemvars.inc

include $(addsuffix Makefile, main/ drivers/ executive/ fs/ lib/ misc/ tasks/)

all: $(BIN) $(SYSTEMVARS_INC)

$(BIN): main.ihx
	hex2bin -out $@ $<

main.ihx: $(RELS) $(MAIN_REL) $(SYSTEMVARS_REL) $(SUBTABLE_REL)
	aslink $(AREA_BASES) -onmuwi main.ihx \
		$(SYSTEMVARS_REL) $(SUBTABLE_REL) $(RELS)

%.rel: %.asm $(INCS)
	$(AS) $@ $<

main/subtable.rel: main/subtable.asm
	$(AS) -g $@ $<

clean: $(CLEANDIRS)
	rm -f $(MAIN_REL) $(RELS) $(BIN) *.ihx *.map
	
flasher:
	tools/flasher -f $(BIN) -s $(6809_SERIAL)

$(SYSTEMVARS_INC): $(BIN)
	# Create the systemvars include for user functions.
	tools/map2systemvars-inc.pl < main.map > $@

subtable:
	# Re-read the current subtable vector table and append any new in
	# ROM external globals
	tools/makesubtable.pl main/subtable.asm < main.map
	# Create the file of user equates, one for each external global
	tools/asm2subtable-inc.pl < main/subtable.asm > user/include/subtable.inc

subtable-init:
	# Setup the subtable. This will rejig all the vectors, breaking
	# binary compatability in user code.
	/bin/echo -e "\t\t.area ROM" > main/subtable.asm
	