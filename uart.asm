; uart driver - for the 16C654

		.include 'system.inc'
		.include 'hardware.inc'
		.include 'debug.inc'

PORTCOUNT	.equ 4

UART_RX_BUF	.equ DEVICE_SIZE+0	; receive circular bufrer
UART_TX_BUF	.equ DEVICE_SIZE+32	; transmit circular buffer
UART_RX_COUNT_H	.equ DEVICE_SIZE+64	; handler receive counter
UART_TX_COUNT_H	.equ DEVICE_SIZE+65	; handler transmit counter
UART_RX_COUNT_U	.equ DEVICE_SIZE+66	; user receive counter
UART_TX_COUNT_U	.equ DEVICE_SIZE+67	; user transmit counter
UART_BASEADDR	.equ DEVICE_SIZE+68	; base address of port
UART_UNIT	.equ DEVICE_SIZE+70	; port number
UART_SIZE	.equ DEVICE_SIZE+71

		.area RAM

uartdevices:	.rmb 2*PORTCOUNT	; all the port devices

		.area ROM

uartdef::	.word uartopen
		.word uartprepare
		.asciz "uart"

uartprepdone:	.asciz 'uart prepare done\r\n'

uartprepare:	debug #uartprepdone
		rts

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

pausedmsg:	.asciz 'task paused '
wakedmsg:	.asciz 'task waked\r\n'
gotcharmsg:	.asciz 'got char\r\n'
donereadmsg:	.asciz 'done read\r\n'

uartread:	pshs b
		lbsr disable
		ldb UART_RX_COUNT_U,x	; get counter
		cmpb UART_RX_COUNT_H,x	; compare..,
		beq 1$			; no character? then return
		leau UART_RX_BUF,x	; get the buffer
		lda b,u			; get the last char written to buf
		incb			; move along to the next
		andb #31		; wrapping to 32 byte window
		stb UART_RX_COUNT_U,x	; and save it
		lbsr enable
		debug #donereadmsg
		setnotzero		; got data
		puls b
		rts
1$:		lbsr enable
		setzero			; got no data
		puls b
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

;;; INTERRUPT

; handle receive interrupts - a has the port number

uartrxmsg:	.asciz 'in uart rx handler\r\n'
uartrxoutmsg:	.asciz 'going out uart rx handler\r\n'

uartrxhandler::	pshs a,b,u
		debug #uartrxmsg
		rola			; two bytes for a pointer
		ldy #uartdevices	; the open devices table
		ldx a,y			; get the device for the port
		ldy UART_BASEADDR,x	; get the base address
		ldb UART_RX_COUNT_H,x	; get current count of bytes
1$:		lda LSR16C654,y		; get the current status
		debuga
		bita #0b0000011		; look for rx state
		beq 2$			; bit clear? no data, out
		lda RHR16C654,y		; get the byte from the port
		leau UART_RX_BUF,x	; get the buffer
		sta b,u			; save the new char in the buffer
		incb			; we got a char
		andb #31		; wrap 0->31
		cmpb UART_RX_COUNT_U,x	; get current user pointer
		bne 1$			; back for more chars unless overrun
2$:		stb UART_RX_COUNT_H,x	; save the buffer write counter
		lbsr driversignal	; signal the task that owns it
		puls a,b,u
		debug #uartrxoutmsg
		rts
