		.include 'system.inc'
		.include 'hardware.inc'
		.include 'debug.inc'

		.area VECTORS

		.word 0x0000		; reserved
		.word 0x0000		; swi3
		.word 0x0000		; swi2
		.word firqinterrupt	; firq
		.word irqinterrupt	; irq
		.word yield		; swi
		.word 0x0000		; nmi
		.word reset		; reset

; this is the start of rom

		.area ROM

; setup stack to the end of ram so it can go grown backwards

reset:		lda #0x02		; map all of the eeprom in
		sta MUDDYSTATE

		ldx #RAMSTART
1$:		clr ,x+
		cmpx #RAMEND
		bne 1$

		disableinterrupts
		clr interruptnest
		clr permitnest

		lds #STACKEND+1

		lda #0xff		; clear all the interrupt routes
		sta NMISOURCESR
		sta IRQSOURCESR
		sta FIRQSOURCESR

		debuginit
		debug ^'Starting debug',DEBUG_GENERAL

		lbsr driverprepare

		lbsr tickerinit		; init the timer
		lbsr memoryinit		; init the heap

		clr reschedflag

		ldy #readytasks
		lbsr initlist
		ldy #waitingtasks
		lbsr initlist

		lda #0xff		; led on
		sta LED
		ldy #0xd000		; small delay
		lbsr delay

		clra
		sta LED			; led off

		ldx #idler
		lbsr newtask
		ldy #idlername
		lbsr settaskname
		debugreg ^'Idle task created: ',DEBUG_GENERAL,DEBUG_REG_X
		stx idletask

		ldx #init
		ldy #initname
		ldu #0
		lbsr createtask

		lbra doneschedule

idlername:	.asciz 'idler'
initname:	.asciz 'init'

; enable interrupts

enable::	debug ^'Enable',DEBUG_ENDDIS
		disableinterrupts
		inc interruptnest
		bgt 1$			; nest value > 0?
		rts
1$:		enableinterrupts
		debug ^'Interrupts now enabled',DEBUG_ENDDIS
		rts

; disable interrupts

disable::	debug ^'Disable',DEBUG_ENDDIS
		disableinterrupts
		dec interruptnest
		ble 1$			; nest value <= 0? 
		enableinterrupts
1$:		rts

; enable multitasking

permit::	inc permitnest
		rts

; disable multitasking

forbid::	dec permitnest
		rts

;;; INTERRUPT CONTEXT

; irq routine - dispatch to device handlers

firqinterrupt:	rti

irqinterrupt:	debug ^'IRQ int detected',DEBUG_INT
		lda ACTIVEIRQ		; get the current state
		ldx #inthandlers	; handler table
		lsla			; table is in words
		ldx a,x			; get the handler routine
		beq 1$			; see if there is no routine
		jmp ,x			; otherwise jump to the routine
1$:		debug ^'No interrupt routine found, halting',DEBUG_INT
2$:		bra 2$			; no interrupt handler found

tailhandler::	debug ^'Tail handler',DEBUG_INT
		lda reschedflag		; check the reschedule flag
		bne 1$			; flag? need to reschedule
		rti			; regular exit
1$:		clr reschedflag		; ensure it wont happen again
		debug ^'Rescheduling',DEBUG_INT
		jmp yield		; reschedule the interrupt target

newlinemsg::	.asciz '\r\n'
newlinez::	.asciz '\r\n'
spacez::	.asciz ' '

		.area DEBUGMSG

; empty placeholder for when debug is disabled