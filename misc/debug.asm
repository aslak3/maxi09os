; debug - port c output

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

.if DEBUG_MODE

		.area RAM

debugbuffer:	.rmb 100

		.area ROM

; these are the debug sections

generalz::	.asciz 'General: '
tasksz::	.asciz 'Tasks: '
enddisz::	.asciz 'Enable/Disable: '
intz::		.asciz 'Interrupt: '
memoryz::	.asciz 'Memory: '
driverz::	.asciz 'Drivers: '
specdrvz::	.asciz 'Low level driver: '

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
		puls a,b,cc,x
		rts

debugprinty::	pshs a,b,cc,x
		tfr y,d
		ldx #debugbuffer
		lbsr wordtoaschex
		clr ,x+
		ldx #debugbuffer
		lbsr debugprint
		puls a,b,cc,x
		rts

debugprinta::	pshs a,b,cc,x
		ldx #debugbuffer
		lbsr bytetoaschex
		clr ,x+
		ldx #debugbuffer
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
		puls a,b,cc,x
		rts

.endif
