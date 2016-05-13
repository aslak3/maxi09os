; our two tasks

		.area RAM (ABS)

task1data:	.rmb 100
task2data:	.rmb 100

		.area ROM (ABS)

device:		.asciz 'uart'
youtyped:	.asciz '\r\nYou typed: '

task1msg:	.asciz '\r\n\r\nHello from TASK ONE on PORT A, enter a string: '

task1:		lda #PORTA
		ldx #device		; we want a uart
		lbsr sysopen

1$:		ldy #task1msg
		lbsr putstr

		ldy #task1data
		lbsr getstr

		ldy #youtyped
		lbsr putstr
		ldy #task1data
		lbsr putstr

		bra 1$
		
task2msg:	.asciz '\r\n\r\nAnd hello from TASK TWO on PORT C, enter a string: '

task2:		lda #PORTC
		ldx #device		; we want a uart
		lbsr sysopen

1$:		ldy #task2msg
		lbsr putstr

		ldy #task2data
		lbsr getstr

		ldy #youtyped
		lbsr putstr
		ldy #task2data
		lbsr putstr

		bra 1$
