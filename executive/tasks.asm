		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl currenttask
		.globl defaultio
		.globl idletask
		.globl waitingtasks
		.globl readytasks
		.globl remove
		.globl addtail
		.globl addhead
		.globl remhead
		.globl remtail
		.globl memoryalloc
		.globl memoryfree
		.globl initlist
		.globl disable
		.globl enable
		.globl copystr
		.globl permitnest
		.globl interruptnest

		.globl _runtimers

STACK		.equ 128

		.area ROM

; createtask - create a task with initial pc in x, name in y, optional
; default io channel in u and make it ready to run

createtask::	pshs a,y
		lbsr newtask		; make a new task, handle in x
		lbsr settaskname	; set the new tasks name
		ldy currenttask		; get the creator task
		sty TASK_PARENT,x	; set the new tasks parent
		stu TASK_DEF_IO,x	; move the default io to new task
		beq 1$			; no default io? no move task io
		lda DEVICE_SIGNAL,u	; get the signal used for def io
		beq 1$			; no signal bits? nothing to move
		lbsr signalfree		; free that bit
		stx DEVICE_TASK,u	; make the new task the owner
		lda #1
		sta DEVICE_SIGNAL,u
		sta TASK_SIGALLOC,x
1$:		ldu TASK_CWD_INODENO,y	; get the old tasks cwd
		stu TASK_CWD_INODENO,x	; save it in the new task
		ldy #readytasks		; get the ready list
		lbsr addtaskto		; add this new task to ready list
		puls a,y
		rts

; new task - x is the initial pc - not normally called by tasks directly,
; but init and the idler are made using this

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
		lda SIGNAL_RESERVED	; not available to tasks
		sta TASK_SIGALLOC,x	; some bits are taken by system
		clra			; clear the others
		sta TASK_SIGWAIT,x	; this one
		sta TASK_SIGRECVD,x	; yeap, this one too
		lda #1
		sta TASK_INTNEST,x	; default interrupt nest to enabled
		sta TASK_PERMITNEST,x	; default permit nest to enabled
		ldy #0
		sty TASK_DISPCOUNT,x	; count of scheduled times
		sty TASK_PARENT,x	; no parent
		sty TASK_DEF_IO,x	; no default io channel
		lda #ERR_INTERNAL	; internal error, until set
		sta TASK_EXIT_CODE,x	; save exit code
		leay TASK_DEAD_LIST,x	; get dead list
		lbsr initlist
		puls a,y,u

		rts

; exittask - exit code in a. move running task to parent's dead children
; list, then signal the parent, which is responsible for freeing our memory. 
; does not return.  the end swi (yield) might be missed if an interrupt
; happens just after enabling interrupts, but this is harmless.

exittask::	debugreg ^'Task exiting: ',DEBUG_TASK,DEBUG_REG_A
		ldx currenttask		; get current task
		lbsr disable		; enter critical section
		lbsr remove		; remove it from the ready list
		ldy TASK_PARENT,x	; get the parent task
		leay TASK_DEAD_LIST,y	; get the list of dead children
		lbsr addtail		; add it to the dead list
		sta TASK_EXIT_CODE,x	; save exit code
		ldx TASK_PARENT,x	; get its parent
		lda #SIGNAL_CHILD	; we are indicating a child exit
		lbsr _intsignal		; send it to the parent
		lbsr enable		; exit critical section
		debugreg ^'Done exiting for task: ',DEBUG_TASK,DEBUG_REG_X
		swi			; yield to another task

; childexit - free the oldest exited child, if there is one. the exit code
; will be in a. if no tasks were waiting to be expunged, then zero is set.

childexit::	pshs y,x
		lda #ERR_GENERAL	; general bad exit code
		ldx currenttask		; get curent task
		leay TASK_DEAD_LIST,x	; get the list of dead children
		lbsr remtaskfrom	; get oldest dead child
		beq 1$			; jump out now if no children
		debugreg ^'Freeing task at: ',DEBUG_TASK,DEBUG_REG_X
		lda TASK_EXIT_CODE,x	; get the exit code into a
		leax -STACK,x
		lbsr memoryfree		; we can finally free the task block
1$:		puls y,x
		rts

; runchild - run the code in x as a child task, pausing the caller until
; it exits. y should contain the name of the child task, and u the default
; io device for that child. on exit, a will contain the exit code.

runchild::	lbsr createtask		; create the task
		lda #SIGNAL_CHILD	; we need to wait for ...
		lbsr wait		; ... the child to exit
		lbsr childexit		; expunge the child
		rts

; set the task in x's name to y

settaskname::	pshs x
		leax TASK_NAME,x	; obtain name member
		lbsr copystr		; copy the string in y
		puls x			; get the task pointer back
		rts

; allocate the first avaialble signal bit, returning a bit mask in a

signalalloc::	debug ^'Allocating signal',DEBUG_TASK
		pshs b,x
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
3$:		debugreg ^'Allocd signal: ',DEBUG_TASK,DEBUG_REG_A
		puls b,x
		rts			; if no match, a will be 0

; signalfree - free the signal at a

signalfree::	pshs x
		ldx currenttask		; get the current task pointer
		coma			; invert the unneeded bits
		anda TASK_SIGALLOC,x	; mask out all but the free bits
		sta TASK_SIGALLOC,x	; update the allocated bits
		puls x
		rts

; wait - wait on signal mask a

wait::		debugreg ^'Start wait for signal: ',DEBUG_TASK,DEBUG_REG_A
		pshs b,x,y
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
		debugreg ^'End wait, got signal: ',DEBUG_TASK,DEBUG_REG_A
		lbsr enable		; leave critical section
		puls b,x,y
		rts

; user space signaler - signal the task in x with the signal in a,
; scheduling the target of the signal next, assuming its listening

signal::	debugreg ^'Signalling the task: ',DEBUG_TASK,DEBUG_REG_A|DEBUG_REG_X
		lbsr disable		; enter criticial section
		lbsr _intsignal		; use the interrupt signal sender
		swi			; now reschedule, returning later
		lbsr enable		; leave critial section
		rts

;; INTERNAL

; signal action, only call with interrupts disabled

_intsignal::	debugreg ^'Interrupt signalling the task: ',DEBUG_INT,DEBUG_REG_A|DEBUG_REG_X
		pshs y
		ora TASK_SIGRECVD,x	; or in the new sigs with current
		sta TASK_SIGRECVD,x	; and save them in the target task
		bita TASK_SIGWAIT,x	; mask the current listening set
		beq 1$			; other end not listening; no wakey
		debug ^'Task is waiting for the signal',DEBUG_TASK
		lbsr remove		; remove from whatever queue
		ldy #readytasks		; and put it on
		lbsr addtail		; ... the ready queue
1$:		debug ^'Done in initsignal',DEBUG_TASK
		puls y
		rts

;; PRIVATE

; add the node in x to the tail of the list in y, disabling as we go

addtaskto:	lbsr disable		; enter critical section
		lbsr addtail		; add to the end
		lbsr enable		; leave critical section
		rts

; remove the head of the list in y, disabling as we go

remtaskfrom:	lbsr disable		; enter critical section
		lbsr remhead		; add to the end
		lbsr enable		; leave critical section
		rts

; remove the node in x, disabling as we go

remtask:	lbsr disable		; enter critical section
		lbsr remove		; remove the node
		lbsr enable		; leave critical section
		rts

;;; INTERRUPT

; ticker

_tickerhandler::debug ^'Ticker handler',DEBUG_INT
		lda T1CL6522		; clear interrupt

		lbsr _runtimers		; run all the timer devices

_yield::	debug ^'Manual yield entry',DEBUG_TASK
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
		beq _doneschedule	; only one task, so done already

		ldy #readytasks		; get the list of ready tasks
		lbsr remtail		; remvoe the tail and add ...
		lbsr addhead		; ... it to the head, rotating it

; schedule the task in x to run - also the schedular's entry point from
; main

_doneschedule::	debugxtask ^'Scheduling the task: ',DEBUG_TASK
		stx currenttask		; set the pointer for current task
		lds TASK_SP,x		; setup the stack from the task
		lda TASK_INTNEST,x	; get the int nest count from task
		sta interruptnest	; restore the interrupt nest count
		lda TASK_PERMITNEST,x	; get the permit nest count from task
		sta permitnest		; restore the permit nest count
		ldy TASK_DEF_IO,x	; get this new tasks def io
		sty defaultio		; save this in a global for ease
		ldy TASK_DISPCOUNT,x	; get the dispatch counter
		leay 1,y		; increment it
		sty TASK_DISPCOUNT,x	; and save it back
		rti			; resume next task

scheduleidle:	ldx idletask		; get the idle task handlee
		debug ^'Scheduling idler',DEBUG_TASK
		bra _doneschedule	; it will be made the current task
