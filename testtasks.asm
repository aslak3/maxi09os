; our two tasks

		.area RAM (ABS)

task1data:	.rmb 100
task2data:	.rmb 100

		.area ROM (ABS)

device:		.asciz 'uart'
youtyped:	.asciz '\r\nYou typed: '

task1startmsg:	.asciz 'task 1 starting\r\n'
task1msg:	.asciz '\r\n\r\nHello from TASK ONE on PORT A, enter a string: '

task1:		lda #PORTA
		ldx #device		; we want a uart
		lbsr sysopen

		debug #task1startmsg

1$:		ldy #task1msg
		lbsr putstr

		ldy #task1data
		lbsr getstr

		ldy #youtyped
		lbsr putstr
		ldy #task1data
		lbsr putstr

		bra 1$

task2startmsg:	.asciz 'task2 starting\r\n'		
task2msg:	.asciz '\r\n\r\nAnd hello from TASK TWO on PORT C, enter a string: '

task2:		lda #PORTB
		ldx #device		; we want a uart
		lbsr sysopen

		debug #task2startmsg

1$:		ldy #task2msg
		lbsr putstr

		ldy #task2data
		lbsr getstr

		ldy #youtyped
		lbsr putstr
		ldy #task2data
		lbsr putstr

		bra 1$
