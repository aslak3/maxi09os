; GENERIC DRIVER FUNCTIONS

drivertable:	.word uartdef
		.word 0x0000

; open device by string in x, with optional unit number in a

sysopen:	ldu #drivertable	; setup table search
1$:		ldy ,u			; get the def pointer
		beq 2$			; end of list? exit with null
		leay DRIVER_NAME,y	; get the device name
		lbsr strcmp		; compare against the dev requested
		beq 3$			; not found a match, back to top
		leau 2,u		; move to next record
		bra 1$			; back to top
2$:		ldx #0			; return a null in x
		rts
3$:		ldy ,u
		jmp [DRIVER_OPEN,y]	; this is a jump

; close the device at x

sysclose:	jmp [DEVICE_CLOSE,x]	; this is a jump

; read from a device. x is the device struct, a reg has the result

sysread:	jmp [DEVICE_READ,x]	; this is a jump

; write to a evice. x is the device struct, a has what to write

syswrite:	jmp [DEVICE_WRITE,x]	; this is a jump
