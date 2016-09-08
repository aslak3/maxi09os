; virtual console (screen and keyboard) driver

		.include 'hardware.inc'
		.include 'system.inc'
		.include 'scancodes.inc'
		.include 'debug.inc'

CONSOLECOUNT	.equ 5			; the number of virtual consoles
PORTKEYBOARD	.equ PORTD		; the uart port attached to keybard

CON_RX_BUF	.equ DEVICE_SIZE+0	; receive circular bufrer
CON_TX_BUF	.equ DEVICE_SIZE+32	; transmit circular buffer
CON_RX_COUNT_H	.equ DEVICE_SIZE+64	; handler receive counter
CON_TX_COUNT_H	.equ DEVICE_SIZE+65	; handler transmit counter
CON_RX_COUNT_U	.equ DEVICE_SIZE+66	; user receive counter
CON_TX_COUNT_U	.equ DEVICE_SIZE+67	; user transmit counter
CON_UNIT	.equ DEVICE_SIZE+68	; unit number
CON_CAPSLOCK	.equ DEVICE_SIZE+69	; caps lock on?
CON_SIZE	.equ DEVICE_SIZE+70

		.area RAM

condevices:	.rmb 2*CONSOLECOUNT	; all the port devices
kbdbaseaddr:	.rmb 2			; uart port d base
activeconsole:	.rmb 1			; the active console

		.area ROM

switchtable:	.byte 0
		.byte KEY_F1
		.byte 1
		.byte KEY_F2
		.byte 2
		.byte KEY_F3
		.byte 3
		.byte KEY_F4
		.byte 4
		.byte KEY_F5
		.byte 0xff		; end of table of switch scancodes

consoledef::	.word consoleopen
		.word consoleprep
		.asciz "console"

; consoleprepare -

consoleprep:	lda #PORTKEYBOARD	; open the port attached to...
		lbsr uartllopen		; the keyboard mcu
		sty kbdbaseaddr		; save the base address
		ldb #B9600		; the mcu currently uses 9600...
		lbsr uartllsetbaud	; for its baud rate
		clr activeconsole	; start on the first one
		rts

; console open - open the console unit in a reg, returning the device in x
; as per sysopen

consoleopen:	ldx #CON_SIZE		; allocate the device struct
		lbsr memoryalloc	; get the memory for the struct
		ldy currenttask		; get the current task
		sty DEVICE_TASK,x	; save it so we can signal it
		clr CON_RX_COUNT_H,x	; clear all buffer counters
		clr CON_TX_COUNT_H,x	; ...
		clr CON_RX_COUNT_U,x	; ...
		clr CON_TX_COUNT_U,x	; ...
		clr CON_CAPSLOCK,x	; caps lock off by default
		sta CON_UNIT,x		; save the console port
		ldy #condevices		; uart device pointer table
		lsla			; two bytes for a pointer
		stx a,y			; save the device pointer
		ldy #consoleclose	; save the close pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #consoleread	;  save the read pointer
		sty DEVICE_READ,x	; ... in the device struct
		ldy #consolewrite	; save the write pointer
		sty DEVICE_WRITE,x	; ... in the device struct
		lbsr signalalloc	; get a signal bit
		sta DEVICE_SIGNAL,x	; save it in the device struct
		setzero			; 0 is good
		rts
1$:		ldx #0			; return 0
		setnotzero		; not 0 is bad - port is in use
		rts

; console close - give it the device in x

consoleclose:	lda #PORTKEYBOARD	; obtain the port number for kbd
		lbsr uartllclose
		lbsr remove		; remove it from the uart list
		lbsr memoryfree		; free the open device handle
		rts

; console read - get the last char in the buffer in a

conreadmsg:	.asciz 'console done read\r\n'

consoleread:	pshs b
		lbsr disable
		ldb CON_RX_COUNT_U,x	; get counter
		cmpb CON_RX_COUNT_H,x	; compare..,
		beq 1$			; no character? then return
		leau CON_RX_BUF,x	; get the buffer
		lda b,u			; get the last char written to buf
		incb			; move along to the next
		andb #31		; wrapping to 32 byte window
		stb CON_RX_COUNT_U,x	; and save it
		lbsr enable
		debug #conreadmsg
		setnotzero		; got data
		puls b
		rts
1$:		lbsr enable
		setzero			; got no data
		puls b
		rts

; write to the device in x, reg a, waiting until it's been sent

consolewrite:	rts

;;; INTERRUPT

; handle receive interrupts on consoe uart

conrxmsg:	.asciz 'con in uart rx handler\r\n'
conrxoutmsg:	.asciz 'con going out uart rx handler\r\n'
conswitch:	.asciz 'con switching to console ... \r\n'
consignaling:	.asciz 'con signaling owner task\r\n'
conowned:	.asciz 'con this console is owned\r\n'

conrxhandler::	debug #conrxmsg
1$:		ldy kbdbaseaddr		; get the base address
		lda LSR16C654,y		; get the current status
		debuga
		bita #0b0000011		; look for rx state
		beq 4$			; bit clear? no data, out	
		lda RHR16C654,y		; get the scancode byte from the port
		debuga
		ldy #switchtable	; setup table pointer
2$:		ldb ,y+
		cmpb #0xff		; end of table marker
		beq 3$			; end of list, no match
		cmpa ,y+
		bne 2$			; back for more
		debug #conswitch
		debugb
		stb activeconsole	; save new console number
		bra 5$
3$:		ldx #condevices		; the open devices table
		ldb activeconsole	; get this again
		lslb			; 2 bytes for a pointer
		ldx b,x			; get the device for the active con
		beq 5$			; ignore not open consoles
		debug #conowned
		lbsr mapscancode	; translate the scancode in a
		beq 5$			; not a printable char
		ldb CON_RX_COUNT_H,x	; get current count of bytes
		leau CON_RX_BUF,x	; get the buffer
		sta b,u			; save the new char in the buffer
		incb			; we got a char
		andb #31		; wrap 0->31
		debugb
		stb CON_RX_COUNT_H,x	; save the buffer write count
		cmpb CON_RX_COUNT_U,x	; get current user pointer
		bne 1$			; back for more chars unless overrun
4$:		ldx #condevices
		ldb activeconsole	; get this again
		lslb			; 2 bytes for a pointer
		ldx b,x			; get the device for the active con
		beq 5$			; ignore not open consoles
		debug #consignaling
		debugx
		lsrb
		debugb
		lbsr driversignal	; signal the task that owns it
		debug #conrxoutmsg
5$:		rts

