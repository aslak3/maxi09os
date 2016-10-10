; our two tasks

		.include 'system.inc'
		.include 'debug.inc'
		.include 'hardware.inc'
		.include 'ascii.inc'

		.area RAM

consoledev:	.rmb 2
timerdev:	.rmb 2
waitsigs:	.rmb 1
task1data:	.rmb 200

task2data:	.rmb 200

task3data:	.rmb 200

task4consoledev:.rmb 2
task4uartdev:	.rmb 2
task4waitsigs:	.rmb 1

task5data:	.rmb 200

		.area ROM

consolename:	.asciz 'console'
timername:	.asciz 'timer'
uartname:	.asciz 'uart'

youtyped:	.asciz '\r\nYou typed: '

task1startmsg:	.asciz 'task 1 starting\r\n'
task1msg:	.asciz 'Timer expired\r\n'
buttonmsg:	.asciz 'Key pressed: '
abouttowaitmsg:	.asciz 'About to wait\r\n'
donewaitms:	.asciz 'Done wait\r\n'
startingtimermsg:	.asciz 'Starting timer!\r\n'

timerctrlblk:	.byte 1
		.word 40

bumpblk:	.byte 0
		.word 40*5

task1::		lda #0
		clrb
		ldx #consolename		; we want a console
		lbsr sysopen
		stx consoledev
		ldy #task1startmsg
		lbsr putstr
		lda #ASC_EOT
		lbsr syswrite

		ldx #timername
		lbsr sysopen
		stx timerdev

		debug #task1startmsg

		ldy #timerctrlblk
		lda #TIMERCMD_START
		lbsr syscontrol

		debug #task1msg

1$:		ldx consoledev
		ldy #abouttowaitmsg
		lbsr putstr
		ldx timerdev
		lda DEVICE_SIGNAL,x
		ldx consoledev
		ora DEVICE_SIGNAL,x
		lbsr wait
		sta waitsigs
;		ldx consoledev
;		ldy #donewaitmsg
		lbsr putstr

		lda waitsigs
		ldx timerdev
		bita DEVICE_SIGNAL,x
		bne 3$
2$:		lda waitsigs
		ldx consoledev
		bita DEVICE_SIGNAL,x
		bne 4$
		bra 1$

3$:		ldx consoledev
		ldy #task1msg
		lbsr putstr
		bra 2$

4$:		ldx consoledev
		lbsr sysread
		tfr a,b
		beq 1$
		ldy #buttonmsg
		lbsr putstr
		tfr b,a
		ldx #task1data
		lbsr bytetoaschex
		ldx consoledev
		ldy #task1data
		lbsr putstr
		ldy #newlinemsg
		lbsr putstr
		tfr b,a
		cmpa #0x20
		beq 5$
		bra 4$

5$:		ldx timerdev
		ldy #bumpblk
		lda #TIMERCMD_START
		lbsr syscontrol
		ldx consoledev
		ldy #startingtimermsg
		lbsr putstr
		lbra 1$

task2startmsg:	.asciz 'task2 starting\r\n'		
task2msg:	.asciz '\r\n\r\nAnd hello from TASK TWO on console 1, enter a string: '

task2::		lda #1
		clrb
		ldx #consolename		; we want a console
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

task3startmsg:	.asciz 'task3 starting\r\n'		
task3msg:	.asciz '\r\n\r\nAnd hello from TASK THREE on console 2, enter a string: '

task3::		lda #2
		ldb #1				; big scrolling
		ldx #consolename		; we want a console
		lbsr sysopen

		debug #task3startmsg

1$:		ldy #task3msg
		lbsr putstr

		ldy #task3data
		lbsr getstr

		ldy #youtyped
		lbsr putstr
		ldy #task3data
		lbsr putstr

		bra 1$

task4starting:	.asciz 'Task four on console 3 serial terminal\r\n\r\n'

task4::		lda #3
		ldb #1			; big scrolling
		ldx #consolename
		lbsr sysopen
		stx task4consoledev

		ldy #task4starting
		lbsr putstr

		lda #1
		ldb #B9600
		ldx #uartname
		lbsr sysopen
		stx task4uartdev

task4loop:	ldx task4consoledev
		lda DEVICE_SIGNAL,x
		ldx task4uartdev
		ora DEVICE_SIGNAL,x
		lbsr wait
		sta task4waitsigs
		lda task4waitsigs
		ldx task4consoledev
		bita DEVICE_SIGNAL,x
		bne readconsole
		lda waitsigs
		ldx task4uartdev
		bita DEVICE_SIGNAL,x
		bne readuart
		bra task4loop

readconsole:	ldx task4consoledev
		lbsr sysread
		beq task4loop
		ldx task4uartdev
		lbsr syswrite
		bra readconsole
readuart:	ldx task4uartdev
		lbsr sysread
		beq task4loop
		ldx task4consoledev
		lbsr syswrite
		bra readuart

task5msg:	.asciz '\r\n\r\nAnd hello from TASK FIVE on UART port 1, enter a string: '

task5::		lda #0
		ldb #B19200
		ldx #uartname		; we want a console
		lbsr sysopen

1$:		ldy #task5msg
		lbsr putstr

		ldy #task5data
		lbsr getstr

		ldy #youtyped
		lbsr putstr
		ldy #task5data
		lbsr putstr

		bra 1$
		