		.include '../include/hardware.inc'

		.area RAM (ABS)

		.org 0

flashblock:	.rmb 64			; block of 64 bytes for rx data

		.area ROM (ABS)

; setup the reset vector, last location in rom

		.org 0xfffe
	
		.word reset

; this is the start of the last page in fpga rom

		.org 0xff00

; some constant strings

resetmsg:	.asciz '\r\n***flash with f\r\n'
flashreadymsg:	.asciz '+++'

reset:		lds #STACKEND+1		; system stack grows down from end

		clr LED			; turn LED off

		lda #0xff		; clear all the interrupt routes
		sta NMISOURCESR		; we do not use any ints in loader
		sta IRQSOURCESR
		sta FIRQSOURCESR

		lbsr serialinit		; setup the serial port registers

; copy the loader to ram. this is so we can access all of the eeprom space
; from within the loader, including grabbing the eeprom's reset vector
; so we can start the real eeprom content. this is also needed so we can
; rewrite the eeprom if a flashing signal (f) is sent from the host.
		
		ldx #LOADERSTART	; setup the rom copy to ram
		ldy #LOADERCOPYSTART	; this is the second half of ram
romcopy:	lda ,x+			; read in
		sta ,y+			; and write out
		cmpx #LOADEREND+1	; check to see if we are at the end
		bne romcopy		; copy more

; calculate the ram offset so we can proceed from here running in the copy
; held in ram.

		ldx #ramcopy-LOADERSTART+LOADERCOPYSTART

		jmp ,x			; jump to the new location of flasher

; ram copy start

ramcopy:	ldx #resetmsg		; show prompt for flash
		lbsr serialputstr	; no ints used for serial

		lda #1
		sta LED			; LED on

		lbsr serialgetwto	; wait for a key, getting the command

		clr LED			; LED off

		bne normalstart		; timeout

		cmpa #'f		; compare with 'f' to see if ...
		beq flashing		; .. the remote end has an image

normalstart:	lda #0x02		; write protect eeprom
		sta MUDDYSTATE		; but keep it mapped at ffxx

		jmp [0xfffe]		; jump to new reset vector
 
flashing:	ldx #flashreadymsg	; tell other end it can send now
		lbsr serialputstr

		lda #0x03		; enable eeprom writing
		sta MUDDYSTATE		; and map last page to eeprom

; read 64bytes from the serial port into ram

		ldu #ROMSTART		; setup the counter into rom
inflashblk:	ldx #flashblock		; this is the block in ram we...
		ldb #64			; are copying into
inflash:	bsr serialgetchar	; get the byte from the port
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
		bsr serialputchar	; send the char
		cmpu #ROMEND+1		; see if we are the end of rom
		bne inflashblk		; back to the next block

; done writing, now we are verifying. send the content of the rom back, so
; the sender knows what was written - we can't do anything if it didn't
; write, but at least we know

		ldu #ROMSTART		; back to the start
verflash:	lda ,u+			; get the byte
		lbsr serialputchar	; output it
		cmpu #ROMEND+1
		bne verflash

; we could in theory try again but good or bad, do a reset on the new
; reset vector
		
		bra normalstart		; continue on

; include basic serial routines

		.include 'serial.asm'
