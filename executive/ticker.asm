;;; TIMER ;;;

		.include '../include/system.inc'
		.include '../include/hardware.inc'

		.area ROM

tickerinit::	lda #0b11000000
		sta IER6522		; enable T1 interrupts
        
		lda #0b01000000
		sta ACR6522		; T1 continuous, PB7 disabled

		; 40th of a second?
		lda #0x50
		sta T1CL6522
		lda #0xc3
		sta T1CH6522

		; interrupt handler
		ldx #tickerhandler
		stx inthandlers+(INTPOS6522*2)

		; interrupt register
		lda #INTMASK6522
		sta IRQSOURCESS		; for the timer interrupt

		rts
