; starts a new task, x is the initial pc

		.include 'system.inc'
		.include 'debug.inc'
		.include 'hardware.inc'

		.area ROM

STACK		.equ 256

createtask::	tfr x,y			; save initital pc in y
		ldx #STACK+TASK_SIZE	; STACK bytes of stack per task
		lbsr memoryalloc	; alloc and get stack in y

		leau STACK-12,x		; sp is one frame in from bottom

		lda #0x80		; enable entire stack save and ints
		sta 0,u			; ... at position 0 in stack
		sty 10,u		; save starting pc in stack frame

		leax STACK,x		; this is the start of task struct
		stu TASK_SP,x		; set stack pointer in task struct
		sty TASK_PC,x		; save pc in task struct 
		clra			; for neatness...
		sta TASK_SIGALLOC,x	; clear this
		sta TASK_SIGWAIT,x	; and this
		sta TASK_SIGRECVD,x	; yeap, this too
		lda #1
		sta TASK_INTNEST,x	; clear interrupt nest
		ldy #0
		sty TASK_DISPCOUNT,x	; count of scheduled times

		rts

addtaskto::	lbsr disable
		lbsr addtail
		lbsr enable
		rts

remtask::	lbsr disable
		lbsr remove
		lbsr enable
		rts

; allocate the first avaialble signal bit, returning a bit mask in a

sigallocmsg:	.asciz 'Signal allocation\r\n'

signalalloc::	debug #sigallocmsg
		pshs x
		ldx currenttask		; get current task pointer
		lda #1			; the bit to test
		setnotcarry		; loop exists when test bit rots off
1$:		bcs 3$			; end?
		bita TASK_SIGALLOC,x	; mask with allocated signals
		beq 2$			; found a uncliamed sig?
		rola			; onto the next one
		bra 1$			; back for more
2$:		tfr a,b			; we need to copy the bit
		orb TASK_SIGALLOC,x	; save the combined signals
		stb TASK_SIGALLOC,x	; ...in the task struct
3$:		debuga
		puls x
		rts			; if no match, a will be 0

waitmsg:	.asciz 'Waiting\r\n'
donewaitingmsg:	.asciz 'Done waiting\r\n'

wait::		debug #waitmsg
		pshs x,y,b
		ldx currenttask
		lbsr disable
		sta TASK_SIGWAIT,x	; save what we are waiting for
		bita TASK_SIGRECVD,x	; mask out the unwaited bits
		bne 1$			; already got the signal?
		lbsr remove		; remove task from whatever
		ldy #waitingtasks	; and add it to
		lbsr addtail		; .... the waiting queue
		swi			; will return when we are signaled
1$:		ldb TASK_SIGWAIT,x	; get the mask again
		comb			; invert it
		andb TASK_SIGRECVD,x	; mask away the waited-for bits
		lda TASK_SIGRECVD,x	; read the bits which woke us up
		anda TASK_SIGWAIT,x	; re-mask the waiting bits
		stb TASK_SIGRECVD,x	; and save the unwaited for ones
		debug #donewaitingmsg
		lbsr enable
		puls x,y,b
		rts

signalmsg:	.asciz 'Signaling\r\n'

signal::		debug #signalmsg
		lbsr disable
		lbsr intsignal
		swi			; now reschedule
		lbsr enable
		rts

;;; INTERRUPT

intsignal::	pshs y
		ora TASK_SIGRECVD,x	; or in the new sigs with current
		sta TASK_SIGRECVD,x	; and save them in the target task
		bita TASK_SIGWAIT,x	; mask the current listening set
		beq 1$			; other end not listening; no wakey
		lbsr remove		; remove from whatever queue
		ldy #readytasks		; and put it on
		lbsr addtail		; ... the ready queue
1$:		puls y
		rts
; ticker

tickmsg:	.asciz 'tick\r\n'
yieldmsg:	.asciz 'Yield\r\n'
bobinsmsg:	.asciz 'bobins\r\n'
idlemsg:	.asciz 'Idle\r\n'
rrmsg:		.asciz 'RR\r\n'
finmsg:		.asciz 'Fin\r\n'

tickerhandler::	debug #tickmsg
		lda T1CL6522		; clear interrupt

		lbsr runtimers

yield::		debug #yieldmsg
		ldx currenttask		; get the current task struct
		sts TASK_SP,x		; save the current stack pointer
		lda interruptnest
		sta TASK_INTNEST,x

		ldy #readytasks		; start at the head
		ldx LIST_HEAD,y
		ldy NODE_NEXT,x		; get the first node
		beq scheduleidle	; no tasks, so idle

		ldy NODE_NEXT,y		; this will become the new first
		beq finishschedule	; only one task, so done already

		ldy #readytasks
		lbsr remtail
		lbsr addhead

finishschedule::	debugx
		stx currenttask		; set the pointer for current task
		lds TASK_SP,x		; setup the stack from the task
		lda TASK_INTNEST,x	; get the int nest count from task
		sta interruptnest	; restore the interrupt nest count
		ldy TASK_DISPCOUNT,x	; incremenet the dispatch counter
		leay 1,y
		sty TASK_DISPCOUNT,x
		debugy
		rti			; resume next task

scheduleidle:	ldx idletask
		debug #idlemsg
		bra finishschedule

leddevice:	.asciz 'led'

; idler task

idler::		ldx #leddevice
		lbsr sysopen
1$:		lda #1
		lbsr syswrite
		ldy #0x6000
		lbsr delay
		clra
		lbsr syswrite
		ldy #0x6000
		lbsr delay
		bra 1$

;;;;;;;;;;;;;;; DEBUG

taskmsg:	.asciz 'Task: '
initialpcmsg:	.asciz 'Initial PC: '

;dumptasks:	lbsr putstr
;		ldy TASK_NEXT,y
;		beq dumptaskout
;		tfr y,d
;		ldx #taskmsg
;		lbsr putlabd
;		ldd TASK_PC,y
;		ldx #initialpcmsg
;;		lbsr putlabd
;		bra dumptasks
;dumptaskout:	ldx #newlinemsg
;		lbsr putstr
;		rts

;currenttaskmsg:	.asciz 'Current Task: '
;readytasksmsg:	.asciz 'Ready Tasks\r\n'
;waittasksmsg:	.asciz 'Waiting Tasks\r\n'

;dumpalltasks:	ldd currenttask
;		ldx #currenttaskmsg
;		lbsr putlabd
;		ldx #newlinemsg
;		lbsr putstr
;		ldx #readytasksmsg
;		ldy #readytasks
;		lbsr dumptasks
;		ldx #waittasksmsg
;		ldy #waitingtasks
;		lbsr dumptasks
;		rts
