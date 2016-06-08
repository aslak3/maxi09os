; starts a new task, x is the initial pc

STACK	.equ 256

createtask:	tfr x,y			; save initital pc in y
		ldx #STACK+TASK_SIZE	; STACK bytes of stack per task
		lbsr memoryalloc	; alloc and get stack in y

		leau STACK-12,x		; sp is one frame in from bottom

		lda #0x80		; enable entire stack saving
		sta 0,u			; ... at position 0 in stack
		sty 10,u		; save starting pc in stack frame

		leax STACK,x		; this is the start of task struct
		stu TASK_SP,x		; set stack pointer in task struct
		sty TASK_PC,x		; save pc in task struct
		clra			; for neatness...
		sta TASK_SIGWAIT,x	; clear the signal bits
		sta TASK_SIGRECVD,x	; yeap, both of them

		rts

addtaskto:	lbsr disable
		lbsr addtail
		lbsr enable
		rts

remtask:	lbsr disable
		lbsr remove
remtaskout:	lbsr enable
		rts

;wait:		ldx currenttask
;		sta TASK_SIGWAIT,x	; save what we are waiting for
;;
;		bita TASK_SIGRECVD,x	; mask out the unwaited bits
;		bne waitout		; already got the signal?
;					; if so we don't wait
;
;		lbsr remtask		; remove task from whatever
;
;		ldy #waitingtasks	; and add it to
;		lbsr addtaskto		; .... the waiting queue
;
;		swi			; will return when we are signaled

;waitout:	ldb TASK_SIGWAIT,x	; get the mask again
;		comb			; invert it
;		andb TASK_SIGRECVD,x	; mask away the waited-for bits
;		lda TASK_SIGRECVD,x	; read the bits which woke us up
;		anda TASK_SIGWAIT,x	; re-mask the waiting bits
;		stb TASK_SIGRECVD,x	; and save the unwaited for ones
;
;		rts
;
;signal:		ora TASK_SIGRECVD,x	; or in the new sigs with current
;		sta TASK_SIGRECVD,x	; and save them in the target task
;
;		anda TASK_SIGWAIT,x	; mask the current listening set
;		beq signalout		; other end not listening; no wakey
;
;		lbsr remtask		; remove from whatever queue
;
;		ldy #readytasks		; and put it on
;		lbsr addtaskto		; ... the ready queue
;;
;		swi			; now reschedule
;
;signalout:	rts

; pause the task in x, moving it to the waiting list

pausetask:	pshs y
		lbsr remove
		ldy #waitingtasks
		lbsr addtail
		puls y
		rts

; resume the task in x, moving it to the ready list

resumetask:	pshs y
		lbsr remove
		ldy #readytasks
		lbsr addtail
		puls y
		rts

; timer

yieldmsg:	.asciz 'Yield\r\n'
idlemsg:	.asciz 'Idle\r\n'
rrmsg:		.asciz 'RR\r\n'
finmsg:		.asciz 'Fin\r\n'

timerhandler:	lda T1CL6522		; clear interrupt

yield:		clr LED

		debug #yieldmsg

		ldx currenttask		; get the current task struct
		sts TASK_SP,x		; save the current stack pointer

;		ldy #readytasks		; start at the head
;		ldx LIST_HEAD,y
;		ldy NODE_NEXT,x		; get the first node
;		beq scheduleidle	; no tasks, so idle

;		ldy NODE_NEXT,y		; this will become the new first
;		beq finishschedule	; only one task, so done already

		ldy #readytasks
		debug #rrmsg
		lbsr remtail
		beq scheduleidle	; no tasks, so idle
		lbsr addhead

finishschedule:	debugx
		debug #finmsg
		stx currenttask		; set the pointer for current task
		lds TASK_SP,x
		rti			; resume next task

scheduleidle:	ldx idletask
		debug #idlemsg
		bra finishschedule

idler:		lda #0xff
		sta LED
		bra idler


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
