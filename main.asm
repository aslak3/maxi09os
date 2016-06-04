		.include 'systemvars.asm'

		.include 'hardware.inc'

		.include 'debug.inc'

		.area ROM (ABS)

; yield swi interrupt

		.org 0xfffa

		.word yield

; fast interrupt vector

		.org 0xfff6

		.word firqinterrupt

; normal interrupt vector

		.org 0xfff8

		.word irqinterrupt

; setup the reset vector, last location in rom

		.org 0xfffe
	
		.word reset

; this is the start of rom

		.org 0xc000

; setup stack to the end of ram so it can go grown backwards

reset:		lda #0x02		; map all of the eeprom in
		sta MUDDYSTATE

		ldx #RAMSTART
clearloop:	clr ,x+
		cmpx #RAMEND
		bne clearloop

		disableinterrupts
		clr interruptnest

		lds #STACKEND+1

		lda #0xff		; clear all the interrupt routes
		sta NMISOURCESR
		sta IRQSOURCESR
		sta FIRQSOURCESR

		lbsr debuginit

		lbsr timerinit		; init the timer
;		lbsr uartinit		; uart interrupt routing
;		lbsr serialinit		; setup the console serial port
		lbsr memoryinit		; init the heap

		clr rescheduleflag

		ldy #readytasks
		lbsr initlist
		ldy #waitingtasks
		lbsr initlist

;		ldx #greetingmsg	; greetings!
;		lbsr serialputstr	; output the greeting

		lda #0xff		; led on
		sta LED
		ldy #0xd000		; small delay
		lbsr delay

		clra
		sta LED			; led off

		ldx #idler
		lbsr createtask
		stx idletask

		clra
		clrb
		std readytasks
		std waitingtasks

		ldx #init
		lbsr createtask
		ldy #readytasks
		lbsr addtaskto

		stx currenttask

		lds TASK_SP,x

		lbsr enable

		rti			; start init

; enable interrupts

enable:		disableinterrupts
		inc interruptnest
		bgt enableout		; nest value > 0?
		rts
enableout:	enableinterrupts
		rts

; disable interrupts

disable:	disableinterrupts
		dec interruptnest
		ble disableout		; nest value <= 0? 
		enableinterrupts
		rts
disableout:	disableinterrupts
		rts

; irq routine - dispatch to device handlers

firqinterrupt:	rti

nointmsg:	.asciz 'no interrupt routine found\r\n'

irqinterrupt:	ldx #inthandlers	; handler table
		ldy #intmasks		; mask table
		ldb #INTCOUNT		; 8 interrupts (priorities)
		lda ACTIVEIRQ		; get the current state
1$:		decb			; dec the priority 
		bmi 2$			; exit when -1, to include 0
		bita b,y		; mask the current status
		beq 1$			; zero? back for the next
		rolb			; convert to word list
		jmp [b,x]		; jump to the handler routine
2$:		debug #nointmsg
3$:		bra 3$			; no interrupt handler found

tailmsg:	.asciz 'tail handler\r\n'
reschedmsg:	.asciz 'rescheduling\r\n'

tailhandler:	debug #tailmsg
		lda rescheduleflag	; check the reschedule flag
		bne 1$			; flag? need to reschedule
		rti			; regular exit
1$:		clr rescheduleflag	; ensure it wont happen again
		debug #reschedmsg
		jmp yield		; reschedule the interrupt target

greetingmsg:	.asciz 'MAXI09OS 0.1\r\n'
newlinemsg:	.asciz '\r\n'

; include the various subsystem implementations

		.include 'debug.asm'
		.include 'strings.asm'
		.include 'timer.asm'
		.include 'memory.asm'
		.include 'misc.asm'
		.include 'tasks.asm'
		.include 'io.asm'
		.include 'lists.asm'

		.include 'driver.asm'
		.include 'uart.asm'

		.include 'init.asm'
		.include 'testtasks.asm'
