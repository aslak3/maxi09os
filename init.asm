; our two tasks

		.include 'system.inc'
		.include 'debug.inc'

		.area ROM

startedmsg:	.asciz 'init starting\r\n'

init::		debug #startedmsg

		ldx #task1
		lbsr createtask
		ldy #readytasks
		lbsr addtaskto

		ldx #task2
		lbsr createtask
		ldy #readytasks
		lbsr addtaskto

		ldx #task3
		lbsr createtask
		ldy #readytasks
		lbsr addtaskto

		ldx #task4
		lbsr createtask
		ldy #readytasks
		lbsr addtaskto

		ldx #task5
		lbsr createtask
		ldy #readytasks
		lbsr addtaskto

		lda #0xff
		lbsr wait

again:		bra again

