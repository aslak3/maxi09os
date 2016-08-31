; our two tasks

		.include 'system.inc'
		.include 'hardware.inc'
		.include 'debug.inc'

		.area RAM

portadev:	.rmb 2
consoledev:	.rmb 2
waitsigs:	.rmb 1
task1data:	.rmb 100

portbdev:	.rmb 2
task2data:	.rmb 100

		.area ROM

uartdevice:	.asciz 'uart'
consoledevice:	.asciz 'console'
youtyped:	.asciz '\r\nYou typed: '

abouttowaitmsg:	.asciz 'about to wait\r\n'
task1startmsg:	.asciz 'task 1 starting\r\n'
task1msg:	.asciz 'Timer expired\r\n'
buttonmsg:	.asciz 'Key pressed: '
donewaitmsg:	.asciz 'Done wait\r\n'

bumpblk:	.byte 0
		.word 40*5

task1::		lda #PORTA
		ldb #B19200
		ldx #uartdevice		; we want a uart
		lbsr sysopen
		stx portadev

		lda #0
		ldx #consoledevice
		lbsr sysopen
		stx consoledev

		debug #task1startmsg

1$:		ldx portadev
		ldy #abouttowaitmsg
		lbsr putstr
		ldx consoledev
		lda DEVICE_SIGNAL,x
		ldx portadev
		ora DEVICE_SIGNAL,x
		lbsr wait
		sta waitsigs
		ldx portadev
		ldy #donewaitmsg
		lbsr putstr

		lda waitsigs
		ldx consoledev
		bita DEVICE_SIGNAL,x
		bne 4$
2$:		lda waitsigs
		ldx portadev
		bita DEVICE_SIGNAL,x
		bne 3$
		bra 1$

3$:		ldx portadev
		ldy #task1msg
		lbsr putstr
		bra 1$

4$:		ldx consoledev
		lbsr sysread
		tfr a,b
		beq 1$
		ldx portadev
		ldy #buttonmsg
		lbsr putstr
		tfr b,a
		ldx #task1data
		lbsr bytetoaschex
		ldx portadev
		ldy #task1data
		lbsr putstr
		ldy #newlinemsg
		lbsr putstr
		bra 4$

task2startmsg:	.asciz 'task2 starting\r\n'		
task2msg:	.asciz '\r\n\r\nAnd hello from TASK TWO on PORT B, enter a string: '

task2::		lda #PORTB
		ldb #B19200
		ldx #uartdevice		; we want a uart
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
