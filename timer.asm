; timer driver

		.area RAM (ABS)

timers:		.rmb LIST_SIZE		; list of open timers

		.area ROM (ABS)

timersprepare:	ldy #timers
		lbsr initlist
		rts

; timer device instance struct

TIMER_COUNTER	.equ DEVICE_SIZE+0
TIMER_END	.equ DEVICE_SIZE+2
TIMER_RUNNING	.equ DEVICE_SIZE+4
TIMER_REPEAT	.equ DEVICE_SIZE+5
TIMER_SIZE	.equ DEVICE_SIZE+6

timerdef:	.word timeropen
		.word timersprepare
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
		lbsr addtail
		setnotzero
		rts

; timer close - give it the device in x

timerclose:	lbsr memoryfree		; free the open device handle
		rts

; write to the device in x, reg a is command, reg y is param block

timerctrlmsg:	.asciz 'timer control entered\r\n'
timerstartmsg:	.asciz 'timer started\r\n'

timercontrol:	debug #timerctrlmsg
		cmpa #TIMERCMD_START
		beq starttimer
		cmpa #TIMERCMD_STOP
		beq stoptimer
timercontrolo:	rts

starttimer:	lbsr disable
		lda TIMERCTRL_REP,y
		sta TIMER_REPEAT,x
		ldy TIMERCTRL_END,y
		sty TIMER_END,x
		ldy #0
		sty TIMER_COUNTER,x
		lda #1
		sta TIMER_RUNNING,x
		debug #timerstartmsg
		lbsr enable
		rts
stoptimer:	lbsr disable
		clr TIMER_RUNNING,x
		lbsr enable
		rts

;;; INTERUPT

doingtimermsg:	.asciz 'Doing timer '
timerdonemsg:	.asciz 'Timer done!!!!\r\n'

runtimers:	pshs x,y,a
		ldy #timers		; start with list
		ldx LIST_HEAD,y		; get first node
1$:		ldy NODE_NEXT,x		; we need to test for end
		beq runtimersout	; end of list?
		debug #doingtimermsg
		debugx
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
		debug #timerdonemsg
		lbsr intsignal		; signal the task
		tfr y,x			; back to the device struct in x
3$:		ldx NODE_NEXT,x		; get the next open timer
		bra 1$			; back for more
runtimersout:	puls x,y,a
		rts
