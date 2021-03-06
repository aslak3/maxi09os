; GENERIC DRIVER FUNCTIONS

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl strcmp

		.globl _uartdef
		.globl _consoledef
		.globl _leddef
		.globl _timerdef
		.globl _idedef
		.globl _minixdef
		.globl _joydef
		.globl _spidef
		.globl _intsignal

		.area ROM

drivertable:	.word _uartdef
		.word _consoledef
		.word _leddef
		.word _timerdef
		.word _idedef
		.word _minixdef
		.word _joydef
		.word _spidef
		.word 0x0000

; inits all drivers

; open device by string in x, with optional unit number in a

sysopen::	pshs y,u		; save params for driver open call
		ldu #drivertable	; setup table search
1$:		ldy ,u			; get the def pointer
		beq 2$			; end of list? exit with null
		leay DRIVER_NAME,y	; get the device name
		lbsr strcmp		; compare against the dev requested
		beq 3$			; not found a match, back to top
		leau 2,u		; move to next record
		bra 1$			; back to top
2$:		ldx #0			; return a null in x
		puls y,u		; restore stack for error path
		rts
3$:		ldx ,u			; get the specific driver
		puls y,u		; restore sysopen params for driver
		jmp [DRIVER_OPEN,x]	; this is a jump

; close the device at x

sysclose::	jmp [DEVICE_CLOSE,x]	; this is a jump

; read from a device. x is the device struct, a or y has the result

sysread::	jmp [DEVICE_READ,x]	; this is a jump

; write to a device. x is the device struct, a or y has what to write

syswrite::	jmp [DEVICE_WRITE,x]	; this is a jump

; seek to position y. x is the device struct

sysseek::	jmp [DEVICE_SEEK,x]	; this is a jump

; generic do anything to a device, x is the device struct

syscontrol::	jmp [DEVICE_CONTROL,x]	; this is a jump

; helpers

; signals the task that owns the device in x

_driverprep::	debug ^'Driver prepare start',DEBUG_DRIVER
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

_driversignal::	pshs a,x
		debugreg ^'Signalling owner of device: ',DEBUG_TASK,DEBUG_REG_X
		lda DEVICE_SIGNAL,x	; get interrupt bit
		ldx DEVICE_TASK,x	; get task that owns port
		debugreg ^'Task and signal: ',DEBUG_TASK,DEBUG_REG_A|DEBUG_REG_X
		lbsr _intsignal		; make it next to run
		puls a,x
		rts  

; _devicenotimp - dummy for not implemented sys funciton

_devicenotimp ::debug ^'Not implemented',DEBUG_DRIVER
		rts
