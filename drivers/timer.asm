; timer driver

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl memoryalloc
		.globl memoryfree
		.globl currenttask
		.globl signalalloc
		.globl enable
		.globl disable
		.globl initlist
		.globl addtail
		.globl remove

		.globl _intsignal
		.globl _devicenotimp

; timer device instance struct

structstart	DEVICE_SIZE
member		TIMER_COUNTER,2		; counter for this timer
member		TIMER_END,2		; counter limit value
member		TIMER_RUNNING,1		; is the timer running
member		TIMER_REPEAT,1		; counter is of the repeating type
structend	TIMER_SIZE

		.area RAM

timers:		.rmb LIST_SIZE		; list of open timers

		.area ROM

_timerdef::	.word timeropen
		.word timerprepare
		.asciz "timer"

timerprepare:	pshs y
		ldy #timers		; get the timer list
		lbsr initlist		; and make a valid empty list
		puls y
		rts

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
		lbsr disable		; list is walked in isr, so disable
		lbsr addtail		; add timer to the list
		lbsr enable		; release interrupts
		setzero
		rts

; timer close - give it the device in x

timerclose:	lbsr remove		; remove the node
		lbsr memoryfree		; free the open device handle
		rts

; write to the device in x, reg a is command, reg y is param block

timercontrol:	debug ^'Timer control',DEBUG_DRIVER
		cmpa #TIMERCMD_START	; is it a start message?
		beq starttimer		; if so, start it up
		cmpa #TIMERCMD_STOP	; is it a stop message?
		beq stoptimer		; if so, stop the timer
		setnotzero		; otherwise, input error
		rts
timercontrolo:	setzero			; exit success
		rts

starttimer:	lbsr disable		; stop handler playing with timer
		lda TIMERCTRL_REP,y	; get the repeating timer flag
		sta TIMER_REPEAT,x	; save it in the timer struct
		ldy TIMERCTRL_END,y	; get the counter end value
		sty TIMER_END,x		; save it in the timer struct
		ldy #0			; clear the ...
		sty TIMER_COUNTER,x	; ... current timer value
		lda #1			; and mark the timer as ...
		sta TIMER_RUNNING,x	; running
		debug ^'Timer start',DEBUG_DRIVER
		lbsr enable		; now we can enable ints again
		bra timercontrolo	; back to common exit path
stoptimer:	lbsr disable		; stop handler playing with timer
		clr TIMER_RUNNING,x	; mark the timer as stopped
		lbsr enable		; now we can enable ints again
		bra timercontrolo	; back to common exit path

;;; INTERUPT

_runtimers::	pshs x,y,a
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
		sty TIMER_COUNTER,x	; ... the counter value
		lda #1			; now we can ...
		sta TIMER_RUNNING,x	; ... start it again
2$:		lda DEVICE_SIGNAL,x	; get signal bit for task
		tfr x,y			; save timer device struct
		ldx DEVICE_TASK,x	; get the task for that owns timer
		debug ^'Timer done',DEBUG_INT
		lbsr _intsignal		; signal the task
		tfr y,x			; back to the device struct in x
3$:		ldx NODE_NEXT,x		; get the next open timer
		lbra 1$			; back for more
runtimersout:	puls x,y,a
		rts
