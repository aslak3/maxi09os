; joy driver

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl memoryalloc
		.globl memoryfree
		.globl signalalloc
		.globl signalfree
		.globl disable
		.globl enable

		.globl currenttask

		.globl _devicenotimp
		.globl _intsignal

structstart	DEVICE_SIZE
member		JOY_PORT_ADDR,2		; the hardward address
member		JOY_UNIT,1		; unit number
member		JOY_LAST_POS,1		; the last read value
member		JOY_MOVED,1		; has stick moved since last read?
structend	JOY_SIZE

		.area RAM

joysinuse:	.rmb 2			; device handle for open, null ...
		.rmb 2			; ... for closed

		.area ROM

_joydef::	.word joyopen
		.word 0x0000
		.asciz "joy"

joyportaddrs:	.word JOYPORT0		; unit 0
		.word JOYPORT1		; unit 1

; joy open

joyopen:	pshs y
		lbsr disable		; enter critical section
		lsla			; table is word table
		ldy #joysinuse		; get base addr for inuse table
		ldx a,y			; in use?
		bne 1$			; yes, so out we go
		ldx #JOY_SIZE		; allocate device block
		lbsr memoryalloc	; get the block
		stx a,y			; mark as being in use
		ldy currenttask		; get the current task
		sty DEVICE_TASK,x	; save it so we can signal it
		sta JOY_UNIT,x		; save the unit number
		clr JOY_MOVED,x		; not moved yet!
		clr JOY_LAST_POS,x	; assume stick starts centered
		ldy #joyportaddrs	; get start of base addr table
		ldy a,y			; get base addr
		sty JOY_PORT_ADDR,x	; save the port address
		ldy #joyclose		; save the close pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #joyread		; save the write pointer
		sty DEVICE_READ,x	; ... in the device struct
		ldy #_devicenotimp	; not implemented
		sty DEVICE_WRITE,x	; write
		sty DEVICE_SEEK,x	; seek
		sty DEVICE_CONTROL,x	; and control
		lbsr signalalloc	; get a signal bit
		sta DEVICE_SIGNAL,x	; save it in the device
		lbsr enable		; exit critical section
		setzero
		bra 2$
		rts
1$:		lbsr enable		; exit critical section
		ldx #0			; return 0
		setnotzero		; port is in use
2$:		puls y
		rts

; joy close - give it the device in x

joyclose:	pshs a,y
		lbsr disable
		lda DEVICE_SIGNAL,x	; get signal used by this stick
		lbsr signalfree		; free this signal
		lda JOY_UNIT,x		; get the port number
		lsla			; two bytes per entry
		lbsr memoryfree		; free the open device handle
		ldy #joysinuse		; get the device table
		ldx #0			; mark this entry as ...
		stx a,y			; ... free
		lbsr enable
		puls a,y
		rts

; read to the device in x, reg a

joyread:	tst JOY_MOVED,x		; see if stick has moved
		beq 1$			; no? then tell caller to wait
		lda JOY_LAST_POS,x	; get joy state through port address
		clr JOY_MOVED,x		; mark this read done
		setzero			; no, success			
		bra 2$			; out
1$:		lda #IO_ERR_WAIT	; same value, so signal wait
		setnotzero		; "error"
2$:		rts

; INTERRUPT

; wrapper that checks both joysticks

_polljoys::	pshs x,y
		ldy #joysinuse		; get joys table
		ldx 0,y			; get first stick device
		beq 1$			; skip if not open
		bsr checkjoy		; check this joystick
1$:		ldx 2,y			; get second stick device
		beq 2$			; skip if not open
		bsr checkjoy		; check this joystick
2$:		puls x,y
		rts

; check the joystick in x to see if it has moved since last check

checkjoy:	pshs a,x
		lda [JOY_PORT_ADDR,x]	; get current position
		coma			; invert so 0=not moved
		cmpa JOY_LAST_POS,x	; compare it with previous position
		beq checkjoyout		; no change, so all done
		sta JOY_LAST_POS,x	; save new position
		lda #1			; the stick has moved ...
		sta JOY_MOVED,x		; this is cleared by a read
		lda DEVICE_SIGNAL,x     ; get signal bit for task
		ldx DEVICE_TASK,x       ; get the task for that owns timer
		debug ^'Joystick moved; signalling',DEBUG_INT
		lbsr _intsignal         ; signal the task
checkjoyout:	puls a,x
		rts
