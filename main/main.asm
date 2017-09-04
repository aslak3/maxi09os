		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl interruptnest
		.globl permitnest
		.globl reschedflag
		.globl readytasks
		.globl initlist
		.globl waitingtasks
		.globl newtask
		.globl settaskname
		.globl delay
		.globl idletask
		.globl createtask
		.globl inthandlers

		.globl _idler
		.globl _init
		.globl _monitorstart
		.globl _yield
		.globl _memoryinit
		.globl _doneschedule
		.globl _tickerinit
		.globl _driverprep

		.area VECTORS

		.word 0x0000		; reserved
		.word 0x0000		; swi3
		.word _monitorstart	; swi2 (see executive/monitor)
		.word firqinterrupt	; firq
		.word irqinterrupt	; irq
		.word _yield		; swi (see executive/tasks)
		.word 0x0000		; nmi
		.word reset		; reset

; this is the start of rom

		.area ROM

reset:		ldx #RAMSTART		; start at the beginning of ram

1$:		clr ,x+			; clear a byte and inc pointer
		cmpx #RAMEND		; at the end?
		bne 1$			; no? then keep going

		disableinterrupts	; disable interrupts
		clr interruptnest	; set interrupt nest counter to 0
		clr permitnest		; and the permit nest counter to 0

; setup stack to the end of ram so it can go grown backwards

		lds #STACKEND+1		; with no ints, we can setup s

		lda #0xff		; clear all the interrupt routes
		sta NMISOURCESR		; ...
		sta IRQSOURCESR		; ...
		sta FIRQSOURCESR	; ...

		debuginit		; init the debug uart port
		debug ^'Starting debug',DEBUG_GENERAL

		lbsr _driverprep	; prepare all drivers

		lbsr _tickerinit	; init the timer
		lbsr _memoryinit	; init the heap

		clr reschedflag		; don't resched after interrupt

		ldy #readytasks		; init some lists
		lbsr initlist		; first the ready task list
		ldy #waitingtasks	; init another list
		lbsr initlist		; now the waiting task list

		lda #0xff		; led on
		sta LED			; just so we can see how far
		ldy #0xd000		;  ... small delay ...
		lbsr delay		; the boot has got

		clra
		sta LED			; led off

		ldx #_idler		; the idler task routine
		lbsr newtask		; needs to be created
		ldy #idlername		; and ...
		lbsr settaskname	; ... it needs a name
		debugreg ^'Idle task created: ',DEBUG_GENERAL,DEBUG_REG_X
		stx idletask		; this is so we can schedule it

		ldx #_init		; init is the mummy of all tasks
		ldy #initname		; set the name
		ldu #0			; no default io
		lbsr createtask		; create the task and make it ready

		lbra _doneschedule	; fall to the bottom of the sched'er

idlername:	.asciz 'idler'
initname:	.asciz 'init'

; enable interrupts

enable::	debug ^'Enable',DEBUG_ENDDIS
		disableinterrupts
		inc interruptnest
		bgt 1$			; nest value > 0?
		bra 2$
1$:		enableinterrupts
		debug ^'Interrupts now enabled',DEBUG_ENDDIS
2$:		rts

; disable interrupts

disable::	debug ^'Disable',DEBUG_ENDDIS
		disableinterrupts
		dec interruptnest
;		ble 1$			; nest value <= 0? 
;		enableinterrupts
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

; INTERNAL

_tailhandler::	debug ^'Tail handler',DEBUG_INT
		lda reschedflag		; check the reschedule flag
		bne 1$			; flag? need to reschedule
		rti			; regular exit
1$:		clr reschedflag		; ensure it wont happen again
		debug ^'Rescheduling',DEBUG_INT
		jmp _yield		; reschedule the interrupt target

		.area DEBUGMSG

; empty placeholder for when debug is disabled
