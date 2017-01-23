; GENERIC DRIVER FUNCTIONS

		.include 'system.inc'
		.include 'hardware.inc'
		.include 'debug.inc'

		.area ROM

drivertable:	.word uartdef
		.word consoledef
		.word leddef
		.word timerdef
		.word 0x0000

; inits all drivers

driverprepare::	debug ^'Driver prepare start',DEBUG_DRIVER
		ldu #drivertable	; setup table search
1$:		ldy ,u			; get current driver
		beq 3$			; last one? exit
		debugreg ^'Doing driver prpare for: ',DEBUG_DRIVER,DEBUG_REG_Y
		ldx DRIVER_PREPARE,y	; get prepare routine from driver
		beq 2$			; not one set? exit
		jsr [DRIVER_PREPARE,y]	; run the prepare routine
2$:		leau 2,u		; get the next driver
		bra 1$			; back for more
3$:		debug ^'Driver prpare end',DEBUG_DRIVER
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

sysctrl::	jmp [DEVICE_CONTROL,x]	; this is a jump

; helpers

; signals the task that owns the device in x

driversignal::	pshs a,x
		debugreg ^'Signalling owner of device: ',DEBUG_TASK,DEBUG_REG_X
		lda DEVICE_SIGNAL,x	; get interrupt bit
		ldx DEVICE_TASK,x	; get task that owns port
		debugreg ^'Task and signal: ',DEBUG_TASK,DEBUG_REG_A|DEBUG_REG_X
		lbsr intsignal		; make it next to run
		puls a,x
		rts  
