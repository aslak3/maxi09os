; debug - port c output

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl wordtoaschex
		.globl bytetoaschex

.if DEBUG_MODE
		.area RAM

debugbuffer:	.rmb 100

		.area ROM

_spacez::	.asciz ' '

; these are the debug sections

_generalz::	.asciz 'General: '
_tasksz::	.asciz 'Tasks: '
_enddisz::	.asciz 'Enable/Disable: '
_intz::		.asciz 'Interrupt: '
_memoryz::	.asciz 'Memory: '
_driverz::	.asciz 'Drivers: '
_taskuserz::	.asciz 'Tasks (user): '
_libz::		.asciz 'Library: '

; write to the debug port the string in x

_debugprint::	pshs a,b,y,cc
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

_debugprinta::	pshs a,b,cc,x
		ldx #debugbuffer
		lbsr bytetoaschex
		clr ,x+
		ldx #debugbuffer
		lbsr _debugprint
		ldx #_spacez
		lbsr _debugprint
		puls a,b,cc,x
		rts

_debugprintb::	pshs a,b,cc,x
		ldx #debugbuffer
		tfr b,a
		lbsr bytetoaschex
		clr ,x+
		ldx #debugbuffer
		lbsr _debugprint
		ldx #_spacez
		lbsr _debugprint
		puls a,b,cc,x
		rts

_debugprintx::	pshs a,b,cc,x
		tfr x,d
		ldx #debugbuffer
		lbsr wordtoaschex
		clr ,x+
		ldx #debugbuffer
		lbsr _debugprint
		ldx #_spacez
		lbsr _debugprint
		puls a,b,cc,x
		rts

_debugprinty::	pshs a,b,cc,x
		tfr y,d
		ldx #debugbuffer
		lbsr wordtoaschex
		clr ,x+
		ldx #debugbuffer
		lbsr _debugprint
		ldx #_spacez
		lbsr _debugprint
		puls a,b,cc,x
		rts

.endif
