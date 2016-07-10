; our two tasks

		.area RAM (ABS)

portadev:	.rmb 2
timerdev:	.rmb 2
waitsigs:	.rmb 1

portbdev:	.rmb 2
task2data:	.rmb 100

		.area ROM (ABS)

uartdevice:	.asciz 'uart'
timerdevice:	.asciz 'timer'
youtyped:	.asciz '\r\nYou typed: '

task1startmsg:	.asciz 'task 1 starting\r\n'
task1msg:	.asciz 'Tick tock...\r\n'
buttonmsg:	.asciz 'Ouch!\r\n'
abouttowaitmsg:	.asciz 'About to wait\r\n'
donewaitmsg:	.asciz 'Done wait\r\n'
startingtimermsg:	.asciz 'Starting timer!\r\n'

timerctrlblk:	.byte 1
		.word 40

bumpblk:	.byte 0
		.word 40*5

task1:		lda #PORTA
		ldx #uartdevice		; we want a uart
		lbsr sysopen
		stx portadev

		ldx #timerdevice
		lbsr sysopen
		stx timerdev

		debug #task1startmsg

		ldy #timerctrlblk
		lda #TIMERCMD_START
		lbsr syscontrol

		debug #task1msg

1$:		ldx portadev
		ldy #abouttowaitmsg
		lbsr putstr
		ldx timerdev
		lda DEVICE_SIGNAL,x
		ldx portadev
		ora DEVICE_SIGNAL,x
		lbsr wait
		sta waitsigs
		ldx portadev
		ldy #donewaitmsg
		lbsr putstr

		lda waitsigs
		ldx timerdev
		bita DEVICE_SIGNAL,x
		bne 3$
2$:		lda waitsigs
		ldx portadev
		bita DEVICE_SIGNAL,x
		bne 4$
		bra 1$

3$:		ldx portadev
		ldy #task1msg
		lbsr putstr
		bra 2$

4$:		ldx portadev
		lbsr sysread
		tfr a,b
		beq 1$
		ldy #buttonmsg
		lbsr putstr
		tfr b,a
		cmpa #0x20
		beq 5$
		bra 4$

5$:		ldx timerdev
		ldy #bumpblk
		lda #TIMERCMD_START
		lbsr syscontrol
		ldx portadev
		ldy #startingtimermsg
		lbsr putstr
		bra 1$

task2startmsg:	.asciz 'task2 starting\r\n'		
task2msg:	.asciz '\r\n\r\nAnd hello from TASK TWO on PORT C, enter a string: '

task2:		lda #PORTB
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
