; our two tasks

startedmsg:	.asciz 'init starting\r\n'

init:		debug #startedmsg

		ldx #task1
		lbsr createtask
		ldy #readytasks
		lbsr addtaskto

		ldx #task2
		lbsr createtask
		ldy #readytasks
		lbsr addtaskto

		lda #0xff
		lbsr wait

again:		bra again

