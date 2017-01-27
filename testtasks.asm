; our two tasks

		.include 'system.inc'
		.include 'debug.inc'
		.include 'hardware.inc'
		.include 'ascii.inc'

		.area RAM

consoledev:	.rmb 2
timerdev:	.rmb 2
waitsigs:	.rmb 1

timertestdata:	.rmb 200

sertermcondev:	.rmb 2
sertermuartdev:	.rmb 2
sertermwaitsigs:.rmb 1
echotestresult:	.rmb 1

		.area ROM

consolenamez:	.asciz 'console'
timernamez:	.asciz 'timer'
uartnamez:	.asciz 'uart'

timertaskstartz:.asciz 'Timer task starting\r\n'
timerexpiredz:	.asciz 'Timer expired\r\n'
keypressedz:	.asciz 'Key pressed: '
abouttowaitz:	.asciz 'About to wait\r\n'
donewaitz:	.asciz 'Done wait\r\n'
startingtimerz:	.asciz 'Starting timer!\r\n'

timerctrlblk:	.byte 1
		.word 40

bumpblk:	.byte 0
		.word 40*5

timertask::	lda #0
		clrb
		ldx #consolenamez		; we want a console
		lbsr sysopen
		stx consoledev
		ldy #timertaskstartz
		lbsr putstr
		lda #ASC_EOT
		lbsr syswrite

		ldx #timernamez
		lbsr sysopen
		stx timerdev

		ldy #timerctrlblk
		lda #TIMERCMD_START
		lbsr sysctrl

1$:		ldx consoledev
		ldy #abouttowaitz
		lbsr putstr
		ldx timerdev
		lda DEVICE_SIGNAL,x
		ldx consoledev
		ora DEVICE_SIGNAL,x
		lbsr wait
		sta waitsigs

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
		ldy #timerexpiredz
		lbsr putstr
		bra 2$

4$:		ldx consoledev
		lbsr sysread
		tfr a,b
		beq 1$
		ldy #keypressedz
		lbsr putstr
		tfr b,a
		ldx #timertestdata
		lbsr bytetoaschex
		ldx consoledev
		ldy #timertestdata
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
		lbsr sysctrl
		ldx consoledev
		ldy #startingtimerz
		lbsr putstr
		lbra 1$

CHILD_TASK	.equ 0
MESSAGE		.equ 2

echogreetz:	.asciz '\r\nHello, enter a string: '
youtypedz:	.asciz '\r\nYou typed: '
childtestz:	.asciz 'test'
memtestz:	.asciz 'mem'
startingchildz:	.asciz '\r\nStarting child\r\n'
echokidz:	.asciz 'echokid'

echotask::	ldx #200
		lbsr memoryalloc
		tfr x,u
		lda #0x42
		sta echotestresult

echotestloop:	ldx defaultio

		ldy #echogreetz
		lbsr putstr

		leay MESSAGE,u
		lbsr getstr

		ldy #youtypedz
		lbsr putstr
		leay MESSAGE,u
		lbsr putstr
		ldy #newlinemsg
		lbsr putstr

		leay MESSAGE,u

		ldx #childtestz
		lbsr strcmp
		beq childtest

		ldx #memtestz
		lbsr strcmp
		beq showmem

		bra echotestloop

exitcodez:	.asciz 'Exit code: '

childtest:	ldx defaultio
		ldy #startingchildz
		lbsr putstr
		lbsr makechild

		ldy #exitcodez
		lbsr putlabb

		lbra echotestloop

makechild:	pshs x,y,u
		ldx #echochild
		ldy #echokidz
		ldu #0
		lbsr runchild
		puls x,y,u
		rts

echochild:	lda #10
1$:		ldy #0xffff
		lbsr delay
		deca
		bne 1$

		lda echotestresult
		inc echotestresult
		lbsr exittask

freez:		.asciz 'Free: '
largestz:	.asciz 'Largest: '

showmem:	lda #MEM_FREE
		lbsr memoryavail
		ldx defaultio
		ldy #freez
		lbsr putlabw
		
		lda #MEM_LARGEST
		lbsr memoryavail
		ldx defaultio
		ldy #largestz
		lbsr putlabw
		
		lbra echotestloop

sertermz:	.asciz 'Serial terminal\r\n\r\n'

sertermtask::	lda #3
		ldb #1			; big scrolling
		ldx #consolenamez
		lbsr sysopen
		stx sertermcondev

		ldy #sertermz
		lbsr putstr

		lda #1
		ldb #B9600
		ldx #uartnamez
		lbsr sysopen
		stx sertermuartdev

sertermloop:	ldx sertermcondev
		lda DEVICE_SIGNAL,x
		ldx sertermuartdev
		ora DEVICE_SIGNAL,x
		lbsr wait
		sta sertermwaitsigs
		lda sertermwaitsigs
		ldx sertermcondev
		bita DEVICE_SIGNAL,x
		bne readconsole
		lda waitsigs
		ldx sertermuartdev
		bita DEVICE_SIGNAL,x
		bne readuart
		bra sertermloop

readconsole:	ldx sertermcondev
		lbsr sysread
		beq sertermloop
		ldx sertermuartdev
		lbsr syswrite
		bra readconsole
readuart:	ldx sertermuartdev
		lbsr sysread
		beq sertermloop
		ldx sertermcondev
		lbsr syswrite
		bra readuart
