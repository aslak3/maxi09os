; timer driver

		.include '../include/system.inc'
		.include '../include/hardware.inc'
		.include '../include/debug.inc'

		.area RAM

timers:		.rmb LIST_SIZE		; list of open timers

		.area ROM

timerprepare:	pshs y
		ldy #timers
		lbsr initlist
		puls y
		rts

; timer device instance struct

structstart	DEVICE_SIZE
member		TIMER_COUNTER,2		; counter for this timer
member		TIMER_END,2		; counter limit value
member		TIMER_RUNNING,1		; is the timer running
member		TIMER_REPEAT,1		; counter is of the repeating type
structend	TIMER_SIZE

timerdef::	.word timeropen
		.word timerprepare
		.asciz "timer"

; timer open

timeropen:	ldx #TIMER_SIZE		; allocate the device struct
		lbsr memoryalloc	; get the memory for the struct
		ldy currenttask         ; get the current task
		sty DEVICE_TASK,x	; save it so we can signal it
		ldy #timerclose		; save the close pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #timercontrol	; save the write pointer
		sty DEVICE_CONTROL,x	; ... in the device struct
		lbsr signalalloc	; get a signal bit
		sta DEVICE_SIGNAL,x	; save it in the device struct
		ldy #0			; clear ...
		sty TIMER_COUNTER,x	; incrementing counter ...
		sty TIMER_END,x		; end value ...
		clr TIMER_RUNNING,x	; clear we are counting flag ...
		clr TIMER_REPEAT,x	; and we are repeating
		ldy #timers
		lbsr disable
		lbsr addtail
		lbsr enable
		setzero
		rts

; timer close - give it the device in x

timerclose:	lbsr remove		; remove the node
		lbsr memoryfree		; free the open device handle
		rts

; write to the device in x, reg a is command, reg y is param block

timercontrol:	debug ^'Timer control',DEBUG_SPEC_DRV
		cmpa #TIMERCMD_START
		beq starttimer
		cmpa #TIMERCMD_STOP
		beq stoptimer
timercontrolo:	setzero
		rts

starttimer:	lbsr disable
		lda TIMERCTRL_REP,y
		sta TIMER_REPEAT,x
		ldy TIMERCTRL_END,y
		sty TIMER_END,x
		ldy #0
		sty TIMER_COUNTER,x
		lda #1
		sta TIMER_RUNNING,x
		debug ^'Timer start',DEBUG_SPEC_DRV
		lbsr enable
		bra timercontrolo
stoptimer:	lbsr disable
		clr TIMER_RUNNING,x
		lbsr enable
		bra timercontrolo

;;; INTERUPT

runtimers::	pshs x,y,a
		ldy #timers		; start with list
		ldx LIST_HEAD,y		; get first node
1$:		ldy NODE_NEXT,x		; we need to test for end
		lbeq runtimersout	; end of list?
		debugreg ^'Doing the timer: ',DEBUG_INT,DEBUG_REG_X
		lda TIMER_RUNNING,x	; see if timer running
		beq 3$			; not running, so next
		ldy TIMER_COUNTER,x	; get current value
		leay 1,y		; tick tock
		sty TIMER_COUNTER,x	; and save
		ldy TIMER_END,x		; get period value
		cmpy TIMER_COUNTER,x	; are we at the end?
		bne 3$			; no? so next timer
		clr TIMER_RUNNING,x	; stop the timer
		lda TIMER_REPEAT,x	; see if we are repeating
		beq 2$			; no restart timer if not repeating
		ldy #0			; reset ...
		sty TIMER_COUNTER,x	; the counter value
		lda #1			;
		sta TIMER_RUNNING,x	; start it again
2$:		lda DEVICE_SIGNAL,x	; get signal bit for task
		tfr x,y			; save timer device struct
		ldx DEVICE_TASK,x	; get the task for that owns timer
		debug ^'Timer done',DEBUG_INT
		lbsr intsignal		; signal the task
		tfr y,x			; back to the device struct in x
3$:		ldx NODE_NEXT,x		; get the next open timer
		lbra 1$			; back for more
runtimersout:	puls x,y,a
		rts
