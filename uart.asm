; uart driver - for the 16C654

; uartopen - port number in a reg

;UART_RX_BUF	.equ DEVICE_SIZE+0
;UART_TX_BUF	.equ DEVICE_SIZE+32
;UART_RX_COUNT	.equ DEVICE_SIZE+64
UART_BASEADDR	.equ DEVICE_SIZE+0	; base address of port
UART_PORT	.equ DEVICE_SIZE+2	; port number
UART_SIZE	.equ DEVICE_SIZE+3

		.area RAM (ABS)

uartportflags:	.rmb 4			; four flags, 0=port a etc

		.area ROM (ABS)

uartdef:	.word uartopen
		.asciz "uart"

; uart open - open the uart port in a reg, returning the device in x
; as per sysopen, y has the driver struct pointer

uartopen:	ldx #uartportflags	; determine if uart is in use
		lbsr disable		; enter critical section
		ldb a,x			; get current state
		bne 1$			; in use?
		ldb #1			; mark it as being in use
		stb a,x			; ...
		lbsr enable		; exit critical section
		ldx #UART_SIZE		; allocate the device struct
		lbsr memoryalloc	; get the memory for the struct
		sta UART_PORT,x		; save the uart port
		sty DEVICE_DRIVER,x	; save the pointer for the dirver
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
		clra			; now we need to clear
		sta IER16C654,y		; ... interrupts
		lda #0xbf		; bf magic to enhanced feature reg
		sta LCR16C654,y		; 8n1 and config baud
		lda #0b00010000
		sta EFR16C654,y		; enable mcr
		lda #0b10000011
		sta LCR16C654,y
		lda #0b10000000
		sta MCR16C654,y		; clock select
		lda #0x01
		sta DLL16C654,y
		lda #0x00
		sta DLM16C654,y		; 115200 baud
		lda #0b00000011
		sta LCR16C654,y		; 8n1 and back to normal
		setzero
		rts
1$:		lbsr enable		; exit critical section
		ldx #0			; return 0
		setnotzero		; port is in use
		rts

; uart close - give it the device in x

uartclose:	lda UART_PORT,x		; obtain the port number
		ldy #uartportflags	; get the top of the open flags
		clr a,y			; mark it unused
		lbsr memoryfree		; free the open device handle
		rts

; read from the device in x, into a, waiting until there's a char

uartread:	pshs y
		ldy UART_BASEADDR,x	; get the base address
1$:		lda LSR16C654,y		; get status
		anda #0b0000001		; input empty?
		beq 1$			; go back and look again
		lda RHR16C654,y		; get the char into a
		puls y
		rts

; write to the device in x, reg a, waiting until it's been sent

uartwrite:	pshs y,b
		ldy UART_BASEADDR,x	; get the base address
1$:		ldb LSR16C654,y		; get status
		andb #0b00100000	; transmit empty
		beq 1$			; wait for port to be idle
		sta THR16C654,y		; output the char
		puls y,b
		rts
