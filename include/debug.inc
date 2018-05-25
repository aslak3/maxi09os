; debug - port c output

.if DEBUG_MODE

		.globl _debugprint
		.globl _debugprintx
		.globl _debugprinty
		.globl _debugprinta
		.globl _debugprintb

		.globl _generalz
		.globl _tasksz
		.globl _enddisz
		.globl _intz
		.globl _memoryz
		.globl _driverz
		.globl _taskuserz
		.globl _libz
		.globl _newlinez
		.globl _spacez

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
		.area DEBUGMSG
label:		.ascii "message"
		.asciz '\r\n'
		.area ROM
		pshs cc,x
		disableinterrupts
		showdebugmode type
		emitdebugstr #label
		puls cc,x
.endif
.endm

.macro		debugreg message,type,register,?label
.if type & DEBUG_MODE
		.area DEBUGMSG
label:		.asciz "message"
		.area ROM
		pshs cc,x
		disableinterrupts
		showdebugmode type
		emitdebugstr #label
.if (register) & DEBUG_REG_A
		lbsr _debugprinta
.endif
.if (register) & DEBUG_REG_B
		lbsr _debugprintb
.endif
.if (register) & DEBUG_REG_X
		lbsr _debugprintx
.endif
.if (register) & DEBUG_REG_Y
		lbsr _debugprinty
.endif
		emitdebugstr #_newlinez
		puls cc,x
.endif
.endm

.macro		debugxtask message,type,?label
.if type & DEBUG_MODE
		.area DEBUGMSG
label:		.asciz "message"
		.area ROM
		pshs cc,x
		disableinterrupts
		showdebugmode type
		emitdebugstr #label
		lbsr _debugprintx
		emitdebugstr #_spacez
		leax TASK_NAME,x
		lbsr _debugprint
		emitdebugstr #_newlinez
		puls cc,x
.endif
.endm

; INTERNAL

.macro		showdebugmode type

.if DEBUG_GENERAL & type
		emitdebugstr #_generalz
.endif
.if DEBUG_TASK & type
		emitdebugstr #_tasksz
.endif
.if DEBUG_ENDDIS & type
		emitdebugstr #_enddisz
.endif
.if DEBUG_INT & type
		emitdebugstr #_intz
.endif
.if DEBUG_MEMORY & type
		emitdebugstr #_memoryz
.endif
.if DEBUG_DRIVER & type
		emitdebugstr #_driverz
.endif
.if DEBUG_TASK_USER & type
		emitdebugstr #_taskuserz
.endif
.if DEBUG_LIB & type
		emitdebugstr #_libz
.endif

.endm

.macro		emitdebugstr addr
		ldx addr
		lbsr _debugprint
.endm

.else 					; no DEBUG_MODE set

.macro		debuginit
.endm

.macro		debug message,type,?label
.endm

.macro		debugreg message,type,register,?label
.endm

.macro		debugxtask message,type,?label
.endm

.endif
