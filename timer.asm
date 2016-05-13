;;; TIMER ;;;

timerinit:	lda #0b11000000
		sta IER6522		; enable T1 interrupts
        
		lda #0b01000000
		sta ACR6522		; T1 continuous, PB7 disabled

		; 20th of a second?
		lda #0xff
		sta T1CL6522
		lda #0xff
		sta T1CH6522

		; interrupt handler
		ldx #timerhandler

		; interrupt register
		lda #INTMASK6522
		sta IRQSOURCESS		; for the timer interrupt

		rts

