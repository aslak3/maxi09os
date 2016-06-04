; uart driver - for the 16C654

; uartopen - port number in a reg

UART_RX_BUF	.equ DEVICE_SIZE+0	; receive circular bufrer
UART_TX_BUF	.equ DEVICE_SIZE+32	; transmit circular buffer
UART_RX_COUNT_H	.equ DEVICE_SIZE+64	; handler receive counter
UART_TX_COUNT_H	.equ DEVICE_SIZE+65	; handler transmit counter
UART_RX_COUNT_U	.equ DEVICE_SIZE+66	; user receive counter
UART_TX_COUNT_U	.equ DEVICE_SIZE+67	; user transmit counter
UART_TASK	.equ DEVICE_SIZE+68	; task that opened the port
UART_BASEADDR	.equ DEVICE_SIZE+70	; base address of port
UART_PORT	.equ DEVICE_SIZE+72	; port number
UART_SIZE	.equ DEVICE_SIZE+73

		.area RAM (ABS)

uartportflags:	.rmb 4			; four flags, 0=port a etc
uarthandles:	.rmb 4*2		; four handles

		.area ROM (ABS)

uartdef:	.word uartopen
		.asciz "uart"

; uart open - open the uart port in a reg, returning the device in x
; as per sysopen, y has the driver struct pointer

uartopen:	ldx #uartportflags	; determine if uart is in use
		lbsr disable		; enter critical section
		ldb a,x			; get current state
		lbne 1$			; in use?
		ldb #1			; mark it as being in use
		stb a,x			; ...
		ldx #UART_SIZE		; allocate the device struct
		lbsr memoryalloc	; get the memory for the struct
		sty DEVICE_DRIVER,x	; save the pointer for the dirver
		ldy currenttask		; get the current task
		sty UART_TASK,x		; save it so we can signal it
		clr UART_RX_COUNT_H,x	; clear all buffer counters
		clr UART_TX_COUNT_H,x	; ...
		clr UART_RX_COUNT_U,x	; ...
		clr UART_TX_COUNT_U,x	; ...
		sta UART_PORT,x		; save the uart port
		ldy #uarthandles	; get the top of the hanlder list
		tfr a,b
		rolb			; multiple the port by 2
		stx b,y			; save the handler
		ldy #uartclose		; save the close pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #uartread		; save the read pointer
		sty DEVICE_READ,x		; ... in the device struct
		ldy #uartwrite		; save the write pointer
		sty DEVICE_WRITE,x	; ... in the device struct
		rola			; multiply by 8
		rola			; ... since there are 8 registers
		rola			; ... in a uart port
		ldy #BASE16C654		; get the base address of quart
		leay a,y		; y is now the base adress of the port
		sty UART_BASEADDR,x	; save the port in the device struct
		lda #0b00000111
		sta FCR16C654,y		; 16 deep fifo
		lda #0b00000001		; receive interrupts
		sta IER16C654,y		; ... interrupts
		lda #0xbf		; bf magic to enhanced feature reg
		sta LCR16C654,y		; 8n1 and config baud
		lda #0b00010000
		sta EFR16C654,y		; enable mcr
		lda #0b10000011
		sta LCR16C654,y
		lda #0b10000000
		sta MCR16C654,y		; clock select
		lda #0x06
		sta DLL16C654,y
		lda #0x00
		sta DLM16C654,y		; 9600 baud
		lda #0b00000011
		sta LCR16C654,y		; 8n1 and back to normal
		ldy #uarthandler
		sty inthandlers+(6*2)
		lda #INTMASKUART	; enable the uart interrupt
		sta IRQSOURCESS		; ... to be routed via disco
		sta intmasks+6
		lbsr enable		; exit critical section
		setzero
		rts
1$:		lbsr enable		; exit critical section
		ldx #0			; return 0
		setnotzero		; port is in use
		rts

; uart close - give it the device in x

uartclose:	lda UART_PORT,x		; obtain the port number
		ldy #uartportflags	; get the top of the open flags
		lbsr disable
		clr a,y			; mark it unused
		lbsr memoryfree		; free the open device handle
		ldx #0			; for the handler pointer
		ldy #uarthandles	; get the top of the hanlder list
		rola			; multiple the port by 2
		stx a,y			; save the handler
		lbsr enable
		rts

; read from the device in x, into a, waiting until there's a char

;uartread:	pshs y
;		ldy UART_BASEADDR,x	; get the base address
;1$:		lda LSR16C654,y		; get status
;		bita #0b0000001		; input empty?
;		beq 1$			; go back and look again
;		lda RHR16C654,y		; get the char into a
;		puls y
;		rts

pausedmsg:	.asciz 'task paused\r\n'
wakedmsg:	.asciz 'task waked\r\n'

uartread:	pshs y
		lbsr disable
1$:		ldb UART_RX_COUNT_U,x	; get counter
		cmpb UART_RX_COUNT_H,x	; compare..
		bne 2$			; got a character? then return it
		tfr x,y			; save the device pointer
		ldx currenttask		; get current task
		lbsr pausetask		; move the task to the waiting list
		debug #pausedmsg
		lbsr enable
		swi			; reschedule
		debug #wakedmsg
		tfr y,x			; restore the device pointer
		bra 1$			; now go back and try again
2$:		leau UART_RX_BUF,x	; get the buffer
		lda b,u			; get the last char written to buf
		incb			; move along to the next
		andb #31		; wrapping to 32 byte window
		stb UART_RX_COUNT_U,x	; and save it
		lbsr enable
		puls y
		rts

; write to the device in x, reg a, waiting until it's been sent

uartwrite:	pshs y,b
		ldy UART_BASEADDR,x	; get the base address
1$:		ldb LSR16C654,y		; get status
		bitb #0b00100000	; transmit empty
		beq 1$			; wait for port to be idle
		sta THR16C654,y		; output the char
		puls y,b
		rts

; interrupt handler for any uart port

uarthandlermsg:	.asciz 'in uarthandler\r\n'
doingtailmsg:	.asciz 'doing tail\r\n'
dotmsg:		.asciz '.\r\n'
decmsg:		.asciz 'decrementing\r\n'
nextdevicemsg:	.asciz 'next device\r\n'
theresadevmsg:	.asciz 'theres a device here\r\n'
intfoundmsg:	.asciz 'interrupt found\r\n'
rxintfoundmsg:	.asciz 'rx interrupt found\r\n'

uarthandler:	debug #uarthandlermsg
		lda #4			; there are four.. ports!
		ldu #uarthandles	; the four device pointers table
1$:		debug #nextdevicemsg
		ldx ,u++		; get the device address
		debugx
		beq 3$			; if 0, back for the next
		debug #theresadevmsg
		ldy UART_BASEADDR,x	; get the port start address
2$:		debugy
		ldb ISR16C654,y
		debugb
		bitb #0b00000001	; if no interrupt set, check next one
		bne 3$
		debug #intfoundmsg
;		bit #0xcc	; receive data ready
;		bne 2$			; 
		debug #rxintfoundmsg
		lbsr uartrxhandler	; handle the rx interrupt
		ldx UART_TASK,x		; get task that owns port
		lbsr resumetask		; make it next to run
		ldb #1			; set the reschedule flag
		stb rescheduleflag	; so the schedule is run at end
3$:		debug #decmsg
		deca
		bne 1$			; check the next port
		debug #doingtailmsg
		jmp tailhandler		; cheeck the reschedule state

; handle receive interrupts - x has the device handle, y the base addr

uartrxmsg:	.asciz 'in uart rx handler\r\n'
uartrxoutmsg:	.asciz 'going out uart rx handler\r\n'

uartrxhandler:	debug #uartrxmsg
		pshs a,b,u
		ldb UART_RX_COUNT_H,x	; get current count of bytes
1$:		lda LSR16C654,y		; get the current status
		debuga
		bita #0b0000001		; look for rx state
		beq 2$			; bit clear? no data, out
		lda RHR16C654,y		; get the byte from the port
		leau UART_RX_BUF,x	; get the buffer
		sta b,u			; save the new char in the buffer
		incb			; we got a char
		andb #31		; wrap 0->31
		cmpb UART_RX_COUNT_U,x	; get current user pointer
		bne 1$			; back for more chars unless overrun
2$:		stb UART_RX_COUNT_H,x	; save the buffer write counter
		puls a,b,u
		debug #uartrxoutmsg
		rts
