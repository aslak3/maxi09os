; our two tasks

		.include 'system.inc'
		.include 'debug.inc'

		.area ROM

startedmsg:	.asciz 'init starting\r\n'

taskname:	.asciz 'mytask'

init::		debug #startedmsg

		ldx #task1
		ldy #taskname
		lbsr createtask

		ldx #task2
		ldy #taskname
		lbsr createtask

		ldx #task3
		ldy #taskname
		lbsr createtask

		ldx #task4
		ldy #taskname
		lbsr createtask

		ldx #task5
		ldy #taskname
		lbsr createtask
		ldy #readytasks

		ldx #monitorstart
		ldy #taskname
		lbsr createtask

		lda #0xff
		lbsr wait

again:		bra again

