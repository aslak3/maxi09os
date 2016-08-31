; GENERIC DRIVER FUNCTIONS

		.include 'system.inc'
		.include 'debug.inc'

		.area ROM

drivertable:	.word uartdef
		.word consoledef
		.word leddef
		.word timerdef
		.word 0x0000

; inits all drivers

drvprepstart:	.asciz 'driverprepare start\r\n'
drvprepend:	.asciz 'driverprepare end\r\n'

driverprepare::	debug #drvprepstart
		ldu #drivertable
1$:		ldy ,u
		beq 3$
		ldx DRIVER_PREPARE,y
		debugx
		beq 2$
		jsr [DRIVER_PREPARE,y]
2$:		leau 2,u
		bra 1$
3$:		debug #drvprepend
		rts	


; open device by string in x, with optional unit number in a

sysopen::	ldu #drivertable	; setup table search
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

sysclose::	jmp [DEVICE_CLOSE,x]	; this is a jump

; read from a device. x is the device struct, a reg has the result

sysread::	jmp [DEVICE_READ,x]	; this is a jump

; write to a evice. x is the device struct, a has what to write

syswrite::	jmp [DEVICE_WRITE,x]	; this is a jump

; generic do anything to a device, x is the device struct

syscontrol::	jmp [DEVICE_CONTROL,x]	; this is a jump

; helpers

; signals the task that owns the device in x

driversignalmsg:	.asciz 'driver signalling task\r\n'

driversignal::	pshs a,x
		debug #driversignalmsg
		lda DEVICE_SIGNAL,x	; get interrupt bit
		ldx DEVICE_TASK,x	; get task that owns port
		debugx
		debuga
		lbsr intsignal		; make it next to run
		puls a,x
		rts  
