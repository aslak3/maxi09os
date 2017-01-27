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

.macro		debug message,type,?label
.if type & DEBUG_MODE
		pshs cc
		disableinterrupts
		showdebugmode type
		.area DEBUGMSG
label:		.ascii "message"
		.asciz '\r\n'
		.area ROM
		emitdebugstr #label
		puls cc
.endif
.endm

.macro		debugreg message,type,register,?label
.if type & DEBUG_MODE
		pshs cc
		disableinterrupts
		showdebugmode type
		.area DEBUGMSG
label:		.asciz "message"
		.area ROM
		emitdebugstr #label
.if (register) & DEBUG_REG_A
		lbsr debugprinta
		emitdebugstr #spacez
.endif
.if (register) & DEBUG_REG_B
		lbsr debugprintb
		emitdebugstr #spacez
.endif
.if (register) & DEBUG_REG_X
		lbsr debugprintx
		emitdebugstr #spacez
.endif
.if (register) & DEBUG_REG_Y
		lbsr debugprinty
		emitdebugstr #spacez
.endif
		emitdebugstr #newlinemsg
		puls cc
.endif
.endm

.macro		debugxtask message,type,?label
.if type & DEBUG_MODE
		pshs cc
		disableinterrupts
		showdebugmode type
		.area DEBUGMSG
label:		.asciz "message"
		.area ROM
		emitdebugstr #label
		lbsr debugprintx
		emitdebugstr #spacez
		pshs x
		leax TASK_NAME,x
		lbsr debugprint
		emitdebugstr #newlinemsg
		puls x
		puls cc
.endif
.endm

.macro		showdebugmode type

.if DEBUG_GENERAL & type
		emitdebugstr #generalz
.endif
.if DEBUG_TASK & type
		emitdebugstr #tasksz
.endif
.if DEBUG_ENDDIS & type
		emitdebugstr #enddisz
.endif
.if DEBUG_INT & type
		emitdebugstr #intz
.endif
.if DEBUG_MEMORY & type
		emitdebugstr #memoryz
.endif
.if DEBUG_DRIVER & type
		emitdebugstr #driverz
.endif
.if DEBUG_SPEC_DRV & type
		emitdebugstr #specdrvz
.endif

.endm

.macro		emitdebugstr addr
		pshs x
		ldx addr
		lbsr debugprint
		puls x
.endm

.else

.macro		debuginit
.endm

.macro		debug message,type,?label
.endm

.macro		debugreg message,type,register,?label
.endm

.macro		debugxtask message,type,?label
.endm

.endif