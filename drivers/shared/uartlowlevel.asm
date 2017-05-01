; uart driver - low level (hardware) layer - for the 16C654

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl disable
		.globl enable
		.globl inthandlers
		.globl uartrxhandler
		.globl conrxhandler
		.globl tailhandler

		.area RAM

uartportflags:	.rmb 4			; four flags, 0=port a etc

		.area ROM

; uart open - open the uart port in a reg, returning the base address
; for the device in y. baud rate selected via b - no baud rate is set

uartllopen::	pshs a,b,x
		ldy #uartportflags	; determine if uart is in use
		lbsr disable		; no  isr till setup complete
		tst a,y			; get current state
		lbne 1$			; in use?
		ldb #1			; mark it as being in use
		stb a,y			; ...
		rola			; multiply by 8
		rola			; ... since there are 8 registers
		rola			; ... in a uart port
		ldy #BASE16C654		; get the base address of quart
		leay a,y		; y is now the base adress of the port
		lda LSR16C654,y         ; get the current status
		bita #0b0000001		; look for rx state
		beq 3$
		lda RHR16C654,y
3$:		lda #0b00000001		; receive interrupts
		sta IER16C654,y		; ... interrupts
		lda #0b01000001
		sta FCR16C654,y		; 16 deep fifo
		ldx #uartllhandler	; get uart handler location
		stx inthandlers+(INTPOSUART*2)	; save it in int table
		lda #INTMASKUART	; enable the uart interrupt
		sta IRQSOURCESS		; ... to be routed via disco
		lbsr enable		; exit critical section
		setzero
		bra 2$
1$:		lbsr enable		; exit critical section
		ldy #0			; return 0
		setnotzero		; port is in use
2$:		puls a,b,x		; restore a and x
		rts

; uart close - give it the port number in a

uartllclose::	pshs y
		ldy #uartportflags	; get the top of the open flags
		lbsr disable
		clr a,y			; mark it unused
		lbsr enable
		puls y
		rts

; sets the rate for the uart port y to rate b (and 8n1)

uartllsetbaud::	pshs a
		lda #0xbf		; bf magic to enhanced feature reg
		sta LCR16C654,y		; 8n1 and config baud	
		lda #0b00010000
		sta EFR16C654,y		; enable mcr
		lda #0b10000011
		sta LCR16C654,y
		lda #0b10000000
		sta MCR16C654,y		; clock select
		stb DLL16C654,y
		clra
		sta DLM16C654,y
		lda #0b00000011
		sta LCR16C654,y		; 8n1 and back to normal
		puls a
		rts

uartllsethwhs::	pshs a
		lda #0xbf		; bf magic to enhanced feature reg
		sta LCR16C654,y		; 8n1 and config baud
		lda #0b10000000		; rts cts
		sta EFR16C654,y
		lda #0b00000011
		sta LCR16C654,y		; 8n1 and back to normal
		puls a
		rts

;;; INTERRUPT

; interrupt handler for any uart port

uartllhandler::	debug ^'In UART LowLevel handler',DEBUG_SPEC_DRV
		ldb BASEPA16C654+ISR16C654
		bitb #0b00000001	; if no interrupt set, check next one
		bne notporta
		lda #0
		lbsr uartrxhandler	; handle the normal uart
		bra uarthandlero
notporta:	ldb BASEPB16C654+ISR16C654
		bitb #0b00000001	; if no interrupt set, check next one
		bne notportb
		lda #1
		lbsr uartrxhandler	; handle the normal uart
		bra uarthandlero
notportb:	ldb BASEPC16C654+ISR16C654
		bitb #0b00000001	; if no interrupt set, check next one
		bne notportc
		lda #2
		lbsr uartrxhandler	; handle the normbal uart
		bra uarthandlero
notportc:	ldb BASEPD16C654+ISR16C654
		bitb #0b00000001	; if no interrupt set, check next one
		bne notportd
		lbsr conrxhandler	; handle the keyboard
		bra uarthandlero
notportd:	debug ^'Unknown UART port',DEBUG_SPEC_DRV
uarthandlero:	debug ^'End UART handler',DEBUG_SPEC_DRV
		jmp tailhandler		; cheeck the reschedule state
