; debug - port c output

		.include 'hardware.inc'
		.include 'debug.inc'

		.area RAM

debugbuffer:	.rmb 100

		.area ROM

startingmsg:	.asciz 'debug starting\r\n'

debuginit::	ldy #BASEPC16C654
		clra
		sta IER16C654,y		; ... interrupts
		lda #0xbf		; bf magic to enhanced feature reg
		sta LCR16C654,y		; 8n1 and config baud
		lda #0b00010000
		sta EFR16C654,y		; enable mcr
		lda #0b10000011
		sta LCR16C654,y
		lda #0b10000000
		sta MCR16C654,y		; clock select
		lda #0x01
		sta DLL16C654,y
		lda #0x00
		sta DLM16C654,y		; 115200 baud
		lda #0b00000011
		sta LCR16C654,y		; 8n1 and back to normal
		debug #startingmsg
		rts

; write to the debug port the string in x

debugprint::	pshs a,b,y,cc
		ldy #BASEPC16C654
1$:		lda ,x+			; byte to send
		beq 3$			; end?
2$:		ldb LSR16C654,y		; get status
		bitb #0b00100000	; transmit empty
		beq 2$			; wait for port to be idle
		sta THR16C654,y		; output the char
		bra 1$
3$:		puls a,b,y,cc
		rts

debugprintx::	pshs a,b,cc,x
		tfr x,d
		ldx #debugbuffer
		lbsr wordtoaschex
		clr ,x+
		ldx #debugbuffer
		lbsr debugprint
		ldx #newlinemsg
		lbsr debugprint
		puls a,b,cc,x
		rts

debugprinty::	pshs a,b,cc,x
		tfr y,d
		ldx #debugbuffer
		lbsr wordtoaschex
		clr ,x+
		ldx #debugbuffer
		lbsr debugprint
		ldx #newlinemsg
		lbsr debugprint
		puls a,b,cc,x
		rts

debugprinta::	pshs a,b,cc,x
		ldx #debugbuffer
		lbsr bytetoaschex
		clr ,x+
		ldx #debugbuffer
		lbsr debugprint
		ldx #newlinemsg
		lbsr debugprint
		puls a,b,cc,x
		rts

debugprintb::	pshs a,b,cc,x
		ldx #debugbuffer
		tfr b,a
		lbsr bytetoaschex
		clr ,x+
		ldx #debugbuffer
		lbsr debugprint
		ldx #newlinemsg
		lbsr debugprint
		puls a,b,cc,x
		rts
