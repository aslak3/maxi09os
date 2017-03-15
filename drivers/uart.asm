; uart driver - for the 16C654

		.include '../include/system.inc'
		.include '../include/hardware.inc'
		.include '../include/debug.inc'

PORTCOUNT	.equ 4

structrunning=	DEVICE_SIZE
member		UART_RX_BUF,32		; rx buffer
member		UART_TX_BUF,32		; tx buffer
member		UART_RX_COUNT_H,2	; rx buffer offset for the handler
member		UART_TX_COUNT_H,2	; unused
member		UART_RX_COUNT_U,2	; rx buffer offset for user code
member		UART_TX_COUNT_U,2	; unused
member		UART_BASEADDR,2		; base hardware address
member		UART_UNIT,1		; unit number for opend uart
structend	UART_SIZE

		.area RAM

uartdevices:	.rmb 2*PORTCOUNT	; all the port devices

		.area ROM

uartdef::	.word uartopen
		.word uartprepare
		.asciz 'uart'

uartprepare:	rts

; uartopen - open the uart port in a reg, returning the device in x
; as per sysopen - b has the baud rate

uartopen:	lbsr uartllopen		; y has base address
		bne 1$			; 0 for good, else bad
		lbsr uartllsetbaud	; set the rate from b
;		lbsr uartllsethwhs	; enable hardware handshaking
		ldx #UART_SIZE		; allocate the device struct
		lbsr memoryalloc	; get the memory for the struct
		sty UART_BASEADDR,x	; save port base address
		ldy #uartdevices	; uart device pointer table
		rola			; two bytes for a pointer
		stx a,y			; save the device pointer
		ldy currenttask		; get the current task
		sty DEVICE_TASK,x	; save it so we can signal it
		clr UART_RX_COUNT_H,x	; clear all buffer counters
		clr UART_TX_COUNT_H,x	; ...
		clr UART_RX_COUNT_U,x	; ...
		clr UART_TX_COUNT_U,x	; ...
		sta UART_UNIT,x		; save the uart port
		ldy #uartclose		; save the close pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #uartread		; save the read pointer
		sty DEVICE_READ,x		; ... in the device struct
		ldy #uartwrite		; save the write pointer
		sty DEVICE_WRITE,x	; ... in the device struct
		ldy #devicenotimpl	; not implemented sub
		sty DEVICE_SEEK,x	; for seek
		sty DEVICE_CONTROL,x	; and for control
		lbsr signalalloc	; get a signal bit
		sta DEVICE_SIGNAL,x	; save it in the device struct
		setzero
		rts
1$:		ldx #0			; return 0
		setnotzero		; port is in use
		rts

; uart close - give it the device in x

uartclose:	lda UART_UNIT,x		; obtain the port number
		lbsr uartllclose
		lbsr remove		; remove it from the uart list
		lbsr memoryfree		; free the open device handle
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

uartread:	pshs b,u
		lbsr disable
		ldb UART_RX_COUNT_U,x	; get counter
		cmpb UART_RX_COUNT_H,x	; compare..,
		beq 1$			; no character? then return
		leau UART_RX_BUF,x	; get the buffer
		lda b,u			; get the last char written to buf
		incb			; move along to the next
		andb #63		; wrapping to 32 byte window
		stb UART_RX_COUNT_U,x	; and save it
		lbsr enable
		debug ^'UART done read',DEBUG_SPEC_DRV
		setzero			; got data
		puls b,u
		rts
1$:		lbsr enable
		setnotzero		; got no data
		puls b,u
		rts

; write to the device in x, reg a, waiting until it's been sent

uartwrite:	pshs y,b
		ldy UART_BASEADDR,x	; get the base address
1$:		ldb LSR16C654,y		; get status
		bitb #0b00100000	; transmit empty
		beq 1$			; wait for port to be idle
		sta THR16C654,y		; output the char
		puls y,b
		setzero
		rts

;;; INTERRUPT

; handle receive interrupts - a has the port number

uartrxhandler::	pshs a,b,u
		debug ^'Start UART RX handler',DEBUG_INT
		rola			; two bytes for a pointer
		ldy #uartdevices	; the open devices table
		ldx a,y			; get the device for the port
		ldy UART_BASEADDR,x	; get the base address
1$:		ldb UART_RX_COUNT_H,x	; get current count of bytes
		lda LSR16C654,y		; get the current status
		debugreg ^'LSR: ',DEBUG_INT,DEBUG_REG_A
		bita #0b0000011		; look for rx state
		beq 2$			; bit clear? no data, out
		lda RHR16C654,y		; get the byte from the port
		leau UART_RX_BUF,x	; get the buffer
		sta b,u			; save the new char in the buffer
		incb			; we got a char
		andb #63		; wrap 0->63
		stb UART_RX_COUNT_H,x	; save the buffer write counter
		subb UART_RX_COUNT_U,x	; get current user pointer
		cmpb #-1		; one behind?
		beq 2$			; back for more chars unless overrun
		cmpb #63
		beq 2$
		bra 1$
2$:		lbsr driversignal	; signal the task that owns it
		puls a,b,u
		debug ^'End UART RX handler',DEBUG_INT
		rts
