; uart driver - for the 16C654

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl memoryalloc
		.globl memoryfree
		.globl currenttask
		.globl signalalloc
		.globl signalfree
		.globl remove
		.globl enable
		.globl disable

		.globl _uartllopen
		.globl _uartllclose
		.globl _uartllsetbaud
		.globl _driversignal
		.globl _devicenotimp

PORTCOUNT	.equ 4			; there are four.... ports!

structstart	DEVICE_SIZE
member		UART_RX_BUF,32		; rx buffer
member		UART_TX_BUF,32		; tx buffer
member		UART_RX_COUNT_H,2	; rx buffer offset for the handler
member		UART_TX_COUNT_H,2	; unused
member		UART_RX_COUNT_U,2	; rx buffer offset for user code
member		UART_TX_COUNT_U,2	; unused
member		UART_BASEADDR,2		; base hardware address
member		UART_LINE_STATUS,1	; last lsr read in
member		UART_UNIT,1		; unit number for opend uart
structend	UART_SIZE

		.area RAM

uartdevices:	.rmb 2*PORTCOUNT	; all the port devices

		.area ROM

_uartdef::	.word uartopen
		.word uartprepare
		.asciz 'uart'

uartprepare:	rts

; uartopen - open the uart port in a reg, returning the device in x
; as per sysopen - b has the baud rate

uartopen:	pshs y
		lbsr disable
		lbsr _uartllopen		; y has base address
		lbne 1$			; 0 for good, else bad
		lbsr _uartllsetbaud	; set the rate from b
;		lbsr _uartllsethwhs	; enable hardware handshaking
		ldx #UART_SIZE		; allocate the device struct
		lbsr memoryalloc	; get the memory for the struct
		sta UART_UNIT,x		; save unit number for uartclose
		sty UART_BASEADDR,x	; save port base address
		debugreg ^'UART open h/w addr: ',DEBUG_SPEC_DRV,DEBUG_REG_Y
		ldy #uartdevices	; uart device pointer table
		lsla			; two bytes for a pointer
		stx a,y			; save the device pointer
		ldy currenttask		; get the current task
		sty DEVICE_TASK,x	; save it so we can signal it
		clr UART_RX_COUNT_H,x	; clear all buffer counters
		clr UART_TX_COUNT_H,x	; ...
		clr UART_RX_COUNT_U,x	; ...
		clr UART_TX_COUNT_U,x	; ...
		clr UART_LINE_STATUS,x	; clear the line status
		ldy #uartclose		; save the close pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #uartread		; save the read pointer
		sty DEVICE_READ,x		; ... in the device struct
		ldy #uartwrite		; save the write pointer
		sty DEVICE_WRITE,x	; ... in the device struct
		ldy #_devicenotimp	; not implemented sub
		sty DEVICE_SEEK,x	; for seek
		sty DEVICE_CONTROL,x	; and for control
		lbsr signalalloc	; get a signal bit
		sta DEVICE_SIGNAL,x	; save it in the device struct
		setzero
		bra 2$
1$:		ldx #0			; return 0
		setnotzero		; port is in use
2$:		lbsr enable
		puls y
		rts

; uart close - give it the device in x

uartclose:	pshs a,y
		lbsr disable
		lda DEVICE_SIGNAL,x	; get the signal used by this dev
		lbsr signalfree		; free the signal used
		lda UART_UNIT,x		; obtain the port number
		debugreg ^'UART close port no: ',DEBUG_SPEC_DRV,DEBUG_REG_A
		lbsr _uartllclose	; close the lowlevel unit
		lbsr memoryfree		; free the open device handle
		lsla			; two bytes for dev table pointers
		ldy #uartdevices	; get the device table
		ldx #0			; clear ...
		stx a,y			; ... the table entry
		lbsr enable
		puls a,y
		rts

; read from the device in x, into a. if there's data set zeero, otherwise
; there's an error. either no data or a break.

uartread:	pshs b,u
		lbsr disable		; disable ints
		lda UART_LINE_STATUS,x	; get current line status
		clr UART_LINE_STATUS,x	; clear the current line status
		bita #0x10		; break?
		bne gotbreak		; got a break, no data
		ldb UART_RX_COUNT_U,x	; get counter
		cmpb UART_RX_COUNT_H,x	; compare..,
		beq nodata		; no character? then return
		leau UART_RX_BUF,x	; get the buffer
		lda b,u			; get the last char written to buf
		incb			; move along to the next
		andb #63		; wrapping to 32 byte window
		stb UART_RX_COUNT_U,x	; and save it
		lbsr enable		; enable ints
		debug ^'UART done read',DEBUG_SPEC_DRV
		setzero			; got data
		bra uartreadout
gotbreak:	lda #IO_ERR_BREAK	; set error state
		bra uartreaderror
nodata:		lda #IO_ERR_WAIT	; caller should wait
uartreaderror:	debugreg ^'UART read error: ',DEBUG_SPEC_DRV,DEBUG_REG_A
		lbsr enable		; exit critical section
		setnotzero		; got no data
uartreadout:	puls b,u
		rts

; write to the device in x, reg a, waiting until it's been sent

uartwrite:	pshs b,y
		ldy UART_BASEADDR,x	; get the base address
1$:		ldb LSR16C654,y		; get status
		bitb #0b00100000	; transmit empty
		beq 1$			; wait for port to be idle
		sta THR16C654,y		; output the char
		setzero
		puls b,y
		rts

;;; INTERRUPT

; handle receive interrupts - a has the port number, b has the isr

_uartrxhandler::pshs a,b,y,u
		debugreg ^'Start UART RX handler, ISR: ',DEBUG_INT,DEBUG_REG_B
		debugreg ^'UART port: ',DEBUG_INT,DEBUG_REG_A
		lsla			; two bytes for a pointer
		ldy #uartdevices	; the open devices table
		ldx a,y			; get the device for the port
		debugreg ^'UART device: ',DEBUG_INT,DEBUG_REG_X
		lbeq portclosed		; port is closed, ignore
		ldy UART_BASEADDR,x	; get the base address
		debugreg ^'UART h/w addr: ',DEBUG_INT,DEBUG_REG_Y
nextint:	andb #0b00111110	; mask out the int status and fifo
		debugreg ^'ISR after masking: ',DEBUG_INT,DEBUG_REG_B
		bitb #0b00000001	; no int?
		lbne noint		; none left? go streight out
		cmpb #0b00000110	; lsr needs to be read
		beq lsrsource
		cmpb #0b00000100	; receive data ready
		beq rxdataready
		cmpb #0b00001100	; receive data timeout
		lbeq rxdatatimeout
		debugreg ^'Unknown interrupt source: ',DEBUG_INT,DEBUG_REG_B
		lbra uartrxout
lsrsource:	lda LSR16C654,y		; get the current status
		debugreg ^'LSR: ',DEBUG_INT,DEBUG_REG_A
		lbra rxonechar
rxdataready:	lda LSR16C654,y		; get the current status
		debugreg ^'RX ready, LSR: ',DEBUG_INT,DEBUG_REG_A
		lbra rxonechar
rxdatatimeout:	lda LSR16C654,y
		debugreg ^'RX timeout, LSR: ',DEBUG_INT,DEBUG_REG_A
		lbra rxonechar
getintstate:	ldb ISR16C654,y		; get interrupt status again
		lbra nextint
uartrxout:	lbsr _driversignal	; signal the task that owns it
nosignal:	puls a,b,y,u
		debug ^'End UART RX handler',DEBUG_INT
		rts
noint:		debug ^'No interrupt generated',DEBUG_INT
		bra uartrxout
portclosed:	debug ^'UART port is closed',DEBUG_INT
		bra nosignal

rxonechar:	tfr a,b			; save the lsr in b
		orb UART_LINE_STATUS,x	; or it over current line status
		stb UART_LINE_STATUS,x	; save the combined line status
		ldb RHR16C654,y		; regardless of lsr get byte from port
		debugreg ^'Got char: ',DEBUG_INT,DEBUG_REG_B
		bita #0b00000011	; look for rx state
		lbeq getintstate	; no data, check ints again on way out
		debug ^'Adding char to ring',DEBUG_INT
		lda UART_RX_COUNT_H,x	; get current count of bytes
		leau UART_RX_BUF,x	; get the buffer
		stb a,u			; save the new char in the buffer
		inca			; we got a char
		anda #63		; wrap 0->63
		sta UART_RX_COUNT_H,x	; save the buffer write counter
		suba UART_RX_COUNT_U,x	; get current user pointer
		cmpa #-1		; one behind?
		lbeq uartrxout		; overrun? exit
		lda LSR16C654,y		; get the current status again
		bra rxonechar		; get more chars
