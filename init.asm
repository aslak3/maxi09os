; our init task

		.include 'system.inc'
		.include 'debug.inc'
		.include 'hardware.inc'

		.area ROM

consolenamez:	.asciz 'console'
uartnamez:	.asciz 'uart'

timertaskname:	.asciz 'timer'
echo1taskname:	.asciz 'echo1'
echo2taskname:	.asciz 'echo2'
sertermtaskname:.asciz 'serterm'
montaskname:	.asciz 'monitor'
echo3taskname:	.asciz 'echo3'

init::		debug ^'Init started',DEBUG_GENERAL

		ldx #timertask
		ldy #timertaskname
		ldu #0
		lbsr createtask

		ldx #consolenamez
		lda #1
		lbsr sysopen
		tfr x,u
		ldx #echotask
		ldy #echo1taskname
		lbsr createtask

		ldx #consolenamez
		lda #2
		lbsr sysopen
		tfr x,u
		ldx #echotask
		ldy #echo2taskname
		lbsr createtask

		ldx #sertermtask
		ldy #sertermtaskname
		ldu #0
		lbsr createtask

		ldx #uartnamez
		lda #0
		ldb #B19200
		lbsr sysopen
		tfr x,u
		ldx #monitorstart
		ldy #montaskname
		lbsr createtask

		clra
		lbsr wait

again:		bra again

