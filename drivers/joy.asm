; joy driver

		.include 'include/system.inc'
		.include 'include/hardware.inc'

		.globl memoryalloc
		.globl memoryfree
		.globl currenttask
		.globl devicenotimpl
		.globl signalalloc
		.globl forbid
		.globl permit

structstart	DEVICE_SIZE
member		JOY_PORT_ADDR,2		; the hardward address
member		JOY_UNIT,1		; unit number
structend	JOY_SIZE

		.area RAM

joysinuse:	.rmb 1			; 1 for open, 0 for closed
		.rmb 1			; for both joysticks

		.area ROM

joydef::	.word joyopen
		.word 0x0000
		.asciz "joy"

joyportaddrs:	.word JOYPORT0		; unit 0
		.word JOYPORT1		; unit 1

; joy open

joyopen:	lbsr forbid		; enter critical section
		ldx #joysinuse		; get base addr for inuse table
		tst a,x			; in use?
		bne 1$			; yes, so out we go
		ldb #1			; mark joystick
		stb a,x			; ... as being in use
		ldx #JOY_SIZE		; allocate device block
		lbsr memoryalloc	; get the block
		sta JOY_UNIT,x		; save the unit number
		ldy #joyportaddrs	; get start of base addr table
		lsla			; table is word table
		ldy a,y			; get base addr
		sty JOY_PORT_ADDR,x	; save the port address
		ldy #joyclose		; save the close pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #joyread		; save the write pointer
		sty DEVICE_READ,x	; ... in the device struct
		ldy #devicenotimpl	; not implemented
		sty DEVICE_WRITE,x	; write
		sty DEVICE_SEEK,x	; seek
		sty DEVICE_CONTROL,x	; and control
		lbsr permit		; exit critical section
		setzero
		rts
1$:		lbsr permit		; exit critical section
		ldx #0			; return 0
		setnotzero		; port is in use
		rts

; joy close - give it the device in x

joyclose:	lbsr forbid
		lda JOY_UNIT,x		; get the port number
		ldy joysinuse		; base of joys in use table
		clr a,y			; mark it free
		lbsr memoryfree		; free the open device handle
		lbsr permit
		rts

; read to the device in x, reg a

joyread:	lda [JOY_PORT_ADDR,x]	; get joy state through port address
		coma			; invert state so high is active
		setzero
		rts
