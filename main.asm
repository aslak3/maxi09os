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

		lds #STACKEND+1

		lda #0xff		; clear all the interrupt routes
		sta NMISOURCESR
		sta IRQSOURCESR
		sta FIRQSOURCESR

		lbsr debuginit

		lbsr driverprepare

		lbsr tickerinit		; init the timer
		lbsr memoryinit		; init the heap

		clr rescheduleflag

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
		lbsr createtask
		debug #idlecreatmsg
		debugx
		stx idletask

		ldx #init
		lbsr createtask
		ldy #readytasks
		lbsr addtaskto

		lbra finishschedule

idlecreatmsg:	.asciz "Idle task created "

; enable interrupts

enablemsg:	.asciz "enable\r\n"
intsenablemsg:	.asciz "ints now enabled\r\n"

enable::	debug #enablemsg
		debugint
		disableinterrupts
		inc interruptnest
		bgt 1$			; nest value > 0?
		rts
1$:		enableinterrupts
		debug #intsenablemsg
		rts

; disable interrupts

disablemsg:	.asciz "disable\r\n"

disable::	debug #disablemsg
		debugint
		disableinterrupts
		dec interruptnest
		ble 1$			; nest value <= 0? 
		enableinterrupts
1$:		rts

;;; INTERRUPT CONTEXT

; irq routine - dispatch to device handlers

firqinterrupt:	rti

irqintmsg:	.asciz 'irq int detected\r\n'
nointmsg:	.asciz 'no interrupt routine found\r\n'

irqinterrupt:	lda ACTIVEIRQ		; get the current state
		ldx #inthandlers	; handler table
		ldy #intmasks		; mask table
		ldb #INTCOUNT		; 8 interrupts (priorities)
		debug #irqintmsg
		debuga
1$:		decb			; dec the priority 
		bmi 2$			; exit when -1, to include 0
		bita b,y		; mask the current status
		beq 1$			; zero? back for the next
		lslb			; convert to word list
		jmp [b,x]		; jump to the handler routine
2$:		debug #nointmsg
;		rti
3$:		bra 3$			; no interrupt handler found

tailmsg:	.asciz 'tail handler\r\n'
reschedmsg:	.asciz 'rescheduling\r\n'

tailhandler::	debug #tailmsg
		lda rescheduleflag	; check the reschedule flag
		bne 1$			; flag? need to reschedule
		rti			; regular exit
1$:		clr rescheduleflag	; ensure it wont happen again
		debug #reschedmsg
		jmp yield		; reschedule the interrupt target

greetingmsg:	.asciz 'MAXI09OS 0.1\r\n'

newlinemsg::	.asciz '\r\n'
