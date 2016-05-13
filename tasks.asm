; starts a new task, x is the initial pc

createtask:	tfr x,y			; save initital pc in y
		ldx #100+TASK_SIZE	; 100 bytes of stack per task
		lbsr memoryalloc	; alloc and get stack in y

		leau 100-12,x		; sp is one frame in from bottom

		lda #0x80		; enable entire stack saving
		sta 0,u			; ... at position 0 in stack
		sty 10,u		; save starting pc in stack frame

		leax 100,x		; this is the start of task struct
		stu TASK_SP,x		; set stack pointer in task struct
		sty TASK_PC,x		; save pc in task struct
		clra			; for neatness...
		clrb			; ...
		std TASK_NEXT,x		; clear the next pointer in the task
		sta TASK_SIGWAIT,x	; clear the signal bits
		sta TASK_SIGRECVD,x	; yeap, both of them

		rts

addtaskto:	lbsr disable
		ldu ,y			; get current first
		stu TASK_NEXT,x		; new node's next is old first
		stx ,y			; make the new one the first
		lbsr enable
		rts

remtaskfrom:	lbsr disable
		ldu TASK_NEXT,x		; get current next
		clra
		clrb
		std TASK_NEXT,x
remtaskloop:	cmpx TASK_NEXT,y
		beq remtaskfound
		ldy TASK_NEXT,y
		bne remtaskloop
		bra remtaskout		; not found, ignore
remtaskfound:	stu TASK_NEXT,y		; set previous to one after removed
remtaskout:	lbsr enable
		rts

wait:		ldx currenttask
		sta TASK_SIGWAIT,x	; save what we are waiting for

		bita TASK_SIGRECVD,x	; mask out the unwaited bits
		bne waitout		; already got the signal?
					; if so we don't wait

		ldy #readytasks		; remove the current task from
		lbsr remtaskfrom	; ... the ready queue

		ldy #waitingtasks	; and add it to
		lbsr addtaskto		; .... the waiting queue

		swi			; will return when we are signaled

waitout:	ldb TASK_SIGWAIT,x	; get the mask again
		comb			; invert it
		andb TASK_SIGRECVD,x	; mask away the waited-for bits
		lda TASK_SIGRECVD,x	; read the bits which woke us up
		anda TASK_SIGWAIT,x	; re-mask the waiting bits
		stb TASK_SIGRECVD,x	; and save the unwaited for ones

		rts

signal:		ora TASK_SIGRECVD,x	; or in the new sigs with current
		sta TASK_SIGRECVD,x	; and save them in the target task

		anda TASK_SIGWAIT,x	; mask the current listening set
		beq signalout		; other end not listening; no wakey

		ldy #waitingtasks	; renove the task
		lbsr remtaskfrom	; ... from the waiting queue

		ldy #readytasks		; and put it on
		lbsr addtaskto		; ... the ready queue

		swi			; now reschedule

signalout:	rts

timerhandler:	lda T1CL6522		; clear interrupt

yield:		ldx currenttask		; get the current task struct
		sts TASK_SP,x		; save the current stack pointer

		ldy readytasks		; start at the head
		tfr y,u			; original first task
		beq scheduleidle	; no tasks, so idle
		ldy TASK_NEXT,y		; this will become the new first
		beq schedulefirst	; only one task, so done already

		sty readytasks		; remove first orig tasks
		
findlastloop:	tfr y,x
		ldy TASK_NEXT,y		; get the next task
		bne findlastloop
		stu TASK_NEXT,x		; make new end task old start
		ldy #0			; no following node
		sty TASK_NEXT,u		; make prev first the last task

		bra finishschedule

scheduleidle:	ldx idletask
		bra finishschedule

schedulefirst:	ldx readytasks

finishschedule:	stx currenttask		; set the pointer for current task
		lds TASK_SP,x
		rti			; resume next task

idler:		bra idler

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
