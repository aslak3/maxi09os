; our init task

		.include 'system.inc'
		.include 'debug.inc'
		.include 'hardware.inc'

		.area ROM

consolenamez:	.asciz 'console'
uartnamez:	.asciz 'uart'

taskname:	.asciz 'mytask'

init::		debug ^'Init started',DEBUG_GENERAL

		ldx #timertask
		ldy #taskname
		ldu #0
		lbsr createtask

		ldx #consolenamez
		lda #1
		lbsr sysopen
		tfr x,u
		ldx #echotask
		ldy #taskname
		lbsr createtask

		ldx #consolenamez
		lda #2
		lbsr sysopen
		tfr x,u
		ldx #echotask
		ldy #taskname
		lbsr createtask

		ldx #sertermtask
		ldy #taskname
		ldu #0
		lbsr createtask

		ldx #monitorstart
		ldy #taskname
		ldu #0
		lbsr createtask

		ldx #uartnamez
		lda #0
		ldb #B19200
		lbsr sysopen
		tfr x,u
		ldx #echotask
		ldy #taskname
		lbsr createtask

		clra
		lbsr wait

again:		bra again

