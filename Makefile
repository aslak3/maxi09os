UPLOAD = $(HOME)/8bitcomputer/eepromprogrammer/upload/upload
FLASHER = ../6809/flasher/flasher

PROG_SERIAL = /dev/ttyUSB0
6809_SERIAL = /dev/ttyS0

BIN = main.bin
MAP = main.map
INC = main.inc

MAIN_ASM = main.asm
ASMS = memory.asm timer.asm systemvars.asm strings.asm \
	tasks.asm testtasks.asm init.asm driver.asm io.asm uart.asm \
	debug.asm lists.asm led.asm

INCS = hardware.inc

all: $(BIN) $(INC)

%.bin: %.ihx
	hex2bin -out $@ $<

%.ihx: %.rel
	aslink -nmwi $<
	
%.rel: $(ASMS) $(INCS) $(MAIN_ASM)
	as6809 -oxs $(MAIN_ASM)

$(INC): $(MAP)
	./map2inc.pl < $(MAP) > $(INC)

clean:
	rm -f $(BIN) $(INC) *.rel *.ihx *.map *.sym DEADJOE

doupload:
	$(UPLOAD) -f $(BIN) -s $(PROG_SERIAL)

doflasher:
	$(FLASHER) -f $(BIN) -s $(6809_SERIAL)
	