; starts a new task, x is the initial pc

		.include 'system.inc'
		.include 'debug.inc'
		.include 'hardware.inc'

		.area ROM

STACK		.equ 256

; createtask - create a task with initial pc in x, name in y and make it
; ready to run

createtask::	pshs y
		lbsr newtask
		lbsr settaskname
		ldy #readytasks
		lbsr addtaskto
		puls y
		rts

; new task - x is the initial pc

newtask::	pshs a,y,u
		tfr x,y			; save initital pc in y
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
		sta TASK_PERMITNEST,x	; clear permit nest
		ldy #0
		sty TASK_DISPCOUNT,x	; count of scheduled times
		puls a,y,u

		rts

; set the task in x's name to y

settaskname::	pshs x
		leax TASK_NAME,x	; obtain name member
		lbsr copystr		; copy the string
		puls x			; get the task pointer back
		rts

; add the node in x to the tail of the list in y, disabling as we go

addtaskto::	lbsr disable		; enter critical section
		lbsr addtail		; add to the end
		lbsr enable		; leave critical section
		rts

; remove the node in x, disabling as we go

remtask::	lbsr disable		; enter critical section
		lbsr remove		; remove the node
		lbsr enable		; leave critical section
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
		ldx currenttask		; obtain the current task
		lbsr disable		; enter critical section
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
		lbsr enable		; leave critical section
		puls x,y,b
		rts

signalmsg:	.asciz 'Signaling\r\n'

; user space signaler - signal the task in x with the signal in a,
; scheduling the target of the schedule next.

signal::	debug #signalmsg
		lbsr disable		; enter criticial section
		lbsr intsignal		; use the interrupt signal sender
		swi			; now reschedule, returning later
		lbsr enable		; leave critial section
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

		lbsr runtimers		; run all the timer devices

yield::		debug #yieldmsg
		tst permitnest		; see if task switch is enabled
		bgt permitted		; >0, so task switching is enabled
		rti			; if not, just return now

permitted:	ldx currenttask		; get the current task struct
		sts TASK_SP,x		; save the current stack pointer
		lda interruptnest	; get the current int nest count
		sta TASK_INTNEST,x	; save it in the outgoing task
		lda permitnest		; same for the permitted nest count
		sta TASK_PERMITNEST,x	; save it to the outgoing task

		ldy #readytasks		; start at the head
		ldx LIST_HEAD,y		; get the first node
		ldy NODE_NEXT,x		; get its following node
		beq scheduleidle	; no tasks, so idle

		ldy NODE_NEXT,y		; this will become the new first
		beq finishschedule	; only one task, so done already

		ldy #readytasks		; get the list of ready tasks
		lbsr remtail		; remvoe the tail and add ...
		lbsr addhead		; ... it to the head, rotating it

finishschedule::	debugx
		stx currenttask		; set the pointer for current task
		lds TASK_SP,x		; setup the stack from the task
		lda TASK_INTNEST,x	; get the int nest count from task
		sta interruptnest	; restore the interrupt nest count
		lda TASK_PERMITNEST,x	; get the permit nest count from task
		sta permitnest		; restore the permit nest count
		ldy TASK_DISPCOUNT,x	; get the dispatch counter
		leay 1,y		; increment it
		sty TASK_DISPCOUNT,x	; and save it back
		debugy
		rti			; resume next task

scheduleidle:	ldx idletask		; get the idle task handlee
		debug #idlemsg
		bra finishschedule	; it will be made the current task

; idler task

leddevice:	.asciz 'led'

idler::		ldx #leddevice		; get the led device name
		lbsr sysopen		; open it
1$:		lda #1			; on
		lbsr syswrite		; make the led turn on
		ldy #0x6000		; delay for a "reasonable" time
		lbsr delay		; and delay
		clra			; off
		lbsr syswrite		; make the led turn off
		ldy #0x6000		; delay for a "reasonable" time
		lbsr delay		; and delay
		bra 1$			; and back for more, forever

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
