; our two tasks

init:		ldx #task1
		lbsr createtask
		ldy #readytasks
		lbsr addtaskto

		ldx #task2
		lbsr createtask
		ldy #readytasks
		lbsr addtaskto

		lbsr wait

again:		bra again

