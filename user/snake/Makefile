AS = ../../tools/as6809-wrapper -oxsw

RELS = snake.rel calibrate.rel game.rel graphics.rel video.rel
BIN = snake.bin

all: $(BIN)

%.bin: %.ihx
	objcopy -I ihex $< -O binary $@

%.ihx: $(RELS)
	aslink -nmwi $@ $(RELS)
	
%.rel: %.asm
	$(AS) $@ $<

clean:
	rm -f $(BIN) *.rel *.ihx *.map *.sym
