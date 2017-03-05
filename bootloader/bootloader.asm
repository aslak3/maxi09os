		.include '../include/hardware.inc'

		.area RAM (ABS)

		.org 0

flashblock:	.rmb 64

		.area ROM (ABS)

		.org 0xc000

realstart:

; setup the reset vector, last location in rom

		.org 0xfffe
	
		.word reset

; this is the start of rom

		.org 0xff00

; START OF GLOBAL READ-ONLY DATA

resetmsg:	.asciz '\r\n***flash with f\r\n'
flashreadymsg:	.asciz '+++'

; setup stack to the end of ram so it can go grown backwards

reset:		lds #STACKEND+1

		lda #0xff		; clear all the interrupt routes
		sta NMISOURCESR
		sta IRQSOURCESR
		sta FIRQSOURCESR

		lbsr serialinit

		ldx #resetmsg		; show prompt for flash
		lbsr serialputstr

		lbsr serialgetwto	; wait for a key, getting the command

		bne normalstart		; timeout

		cmpa #0x66		; 'f'
		beq flashcopy

normalstart:	jmp realstart
 
flashcopy:	ldx #LOADERSTART	; setup the rom copy to ram
		ldy #LOADERCOPYSTART	; this is the second half of ram
romcopy:	lda ,x+			; read in
		sta ,y+			; and write out
		cmpx #LOADEREND+1	; check to see if we are at the end
		bne romcopy		; copy more

		ldx #flasher		; get the location of the flasher code
		leax -LOADERSTART,x	; offset it from the start of rom
		leax LOADERCOPYSTART,x	; offset it forward where it now is 
		jmp ,x			; jump to the new location offlasher

; flasher

flasher:	ldx #flashreadymsg	; tell other end it can send now
		lbsr serialputstr

; read 64bytes from the serial port into ram

		lda #0x03		; enable eeprom writing
		sta MUDDYSTATE		; and map last page to eeprom

		ldu #ROMSTART		; setup the counter into rom
inflashblk:	ldx #flashblock		; this is the block in ram we...
		ldb #64			; are copying into
inflash:	lbsr serialgetchar	; get the byte from the port
		sta ,x+			; store it
		decb			; we store 64bytes
		bne inflash		; back to the next byte

; then write them into rom

		ldx #flashblock		; after we have a block
		ldb #64			; of 64 bytes
outflash:	lda ,x+			; get the byte from ram
		sta ,u+			; and write it into the rom
		decb			; reduce byte counter
		bne outflash		; back for more if non zero

; circa 10ms delay between blocks

		ldx #30000		; setup delay counter
flashdelayloop:	leax -1,x		; dey
		bne flashdelayloop

; tell the uploader that we have written the block, and it can send the
; next one

		lda #0x23		; '#'
		lbsr serialputchar		; send the char
		cmpu #ROMEND+1		; see if we are the end of rom
		bne inflashblk		; back to the next block

; done writing, now we are verifying

		lda #0x02		; write protect eeprom
		sta MUDDYSTATE		; but keep it mapped at ffxx

; send the content of the rom back, so the sender knows what was written -
; we can't do anything if it didn't write, but at least we know

		ldu #ROMSTART		; back to the start
verflash:	lda ,u+			; get the byte
		lbsr serialputchar	; output it
		cmpu #ROMEND+1
		bne verflash

; we could in theory try again but good or bad, do a reset on the new
; reset vector
		
		bra normalstart		; continue on

; include the various subsystem implementations

		.include 'serial.asm'
