; debug - port c output

.if DEBUG_MODE

		.globl debugprint
		.globl debugprintx
		.globl debugprinty
		.globl debugprinta
		.globl debugprintb

		.globl generalz
		.globl tasksz
		.globl enddisz
		.globl intz
		.globl memoryz
		.globl driverz
		.globl specdrvz

.macro 		debuginit
		pshs a,y
		ldy #BASEPC16C654
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
		puls a,y
.endm

.macro		internaldebug addr
		pshs x
		ldx addr
		lbsr debugprint
		puls x
.endm

.macro		debug message,type,?label
.if DEBUG_MODE & type
		showdebugmode type
		.area DEBUGMSG
label:		.ascii "message"
		.asciz '\r\n'
		.area ROM
		pshs x
		ldx #label
		lbsr debugprint
		puls x
.endif
.endm

.macro		debugx type
.if DEBUG_MODE & type
		showdebugmode type
		lbsr debugprintx
.endif
.endm

.macro		debugy type
.if DEBUG_MODE & type
		showdebugmode type
		lbsr debugprinty
.endif
.endm

.macro		debuga type
.if DEBUG_MODE & type
		showdebugmode type
		lbsr debugprinta
.endif
.endm

.macro		debugb type
.if DEBUG_MODE & type
		showdebugmode type
		lbsr debugprintb
.endif
.endm

.macro		showdebugmode type

.if DEBUG_GENERAL & type
		internaldebug #generalz
.endif
.if DEBUG_TASK & type
		internaldebug #tasksz
.endif
.if DEBUG_ENDDIS & type
		internaldebug #enddisz
.endif
.if DEBUG_INT & type
		internaldebug #intz
.endif
.if DEBUG_MEMORY & type
		internalsdebug #memoryz
.endif
.if DEBUG_DRIVER & type
		internaldebug #driverz
.endif
.if DEBUG_SPEC_DRV & type
		internaldebug #specdrvz
.endif

.endm

.macro		debugmessage label,string
.if DEBUG_MODE
label:		.asciz "string"
.endif
.endm

.else

.macro		debuginit
.endm

.macro		debug thing,type
.endm

.macro		debugx type
.endm

.macro		debugy type
.endm

.macro		debuga type
.endm

.macro		debugb type
.endm

.macro		debugmessage label,string
.endm

.endif