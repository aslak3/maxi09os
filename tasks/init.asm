; our init task

		.include 'include/system.inc'
		.include 'include/debug.inc'
		.include 'include/hardware.inc'

		.globl sysopen
		.globl sysclose
		.globl syscontrol
		.globl sysread
		.globl syswrite
		.globl mountminix
		.globl rootsuperblock
		.globl putstr
		.globl currenttask
		.globl timertask
		.globl echotask
		.globl shellstart
		.globl monitorstart
		.globl createtask
		.globl wait
		
		.area RAM

rootdevice:	.rmb 2			; the open root device
initiodevice:	.rmb 2			; init's console

		.area ROM

consolenamez:	.asciz 'console'
uartnamez:	.asciz 'uart'

timertaskname:	.asciz 'timer'
echo1taskname:	.asciz 'echo1'
echo2taskname:	.asciz 'echo2'
echo3taskname:	.asciz 'echo3'
echo4taskname:	.asciz 'echo4'
sertermtaskname:.asciz 'serterm'
montaskname:	.asciz 'monitor'
shell1taskname:	.asciz 'shell1'
shell2taskname:	.asciz 'shell2'
shell3taskname:	.asciz 'shell3'
shell4taskname:	.asciz 'shell4'

rootdevnamez:	.asciz 'ide'
rootunit:	.byte 1
initioz:	.asciz 'uart'
initiounit:	.byte 0
initiobaud:	.byte B19200

; mount the root device, storing it in the variable rootdevice

mountroot:	tst rootunit		; get the root unit and see if its 0
		beq 1$			; no partitions? just mount it
		ldx #rootdevnamez	; get the root device name
		clra			; need to mount 0 first
		lbsr sysopen		; open the device
		lda #IDECMD_READ_MBR	; need to read the partition table
		lbsr syscontrol		; read it
		lbsr sysclose		; now we can close the 0 unit
1$:		ldx #rootdevnamez	; get the root device name
		lda rootunit		; get the real root unit, might be 0
		lbsr sysopen		; now open it
		stx rootdevice		; now save it for init

		lbsr mountminix		; now obtain the superblock
		sty rootsuperblock	; save the super block handle

		rts

openinitio:	ldx #initioz		; device
		lda initiounit		; unit
		ldb initiobaud		; baud rate
		lbsr sysopen
		stx initiodevice
		rts

closeinitio:	ldx initiodevice
		lbsr sysclose
		ldx #0
		stx initiodevice
		rts

writeinitstr:	ldx initiodevice
		lbsr putstr
		rts		

initstartedz:	.asciz '\r\n\r\nInit started\r\n'
rootmountedz:	.asciz 'Root mounted\r\n'

init::		debug ^'Init started',DEBUG_GENERAL

		lbsr openinitio

		ldy #initstartedz
		lbsr writeinitstr

		lbsr mountroot		; mount the root device

		ldy #rootmountedz
		lbsr writeinitstr

		lbsr closeinitio

		ldx currenttask		; get init's task struct
		ldy #1			; root inode is 0001
		sty TASK_CWD_INODENO,x	; this is inherited down the chain

		ldx #timertask
		ldy #timertaskname
		ldu #0
		lbsr createtask

		ldx #consolenamez
		lda #1
		clrb
		lbsr sysopen
		tfr x,u
		ldx #echotask
		ldy #echo1taskname
		lbsr createtask

		ldx #consolenamez
		lda #2
		clrb
		lbsr sysopen
		tfr x,u
		ldx #shellstart
		ldy #shell1taskname
		lbsr createtask

		ldx #consolenamez
		lda #3
		ldb #1
		lbsr sysopen
		tfr x,u
		ldx #shellstart
		ldy #shell2taskname
		lbsr createtask

		ldx #uartnamez
		lda #0
		ldb #B19200
		lbsr sysopen
		tfr x,u
		ldx #shellstart
		ldy #shell3taskname
		lbsr createtask

		ldx #uartnamez
		lda #1
		ldb #B19200
		lbsr sysopen
		tfr x,u
		ldx #monitorstart
		ldy #montaskname
		lbsr createtask

;		ldx #uartnamez
;		lda #1
;		ldb #B19200
;		lbsr sysopen
;		tfr x,u
;		ldx #echotask
;		ldy #echo4taskname
;		lbsr createtask

		clra
		lbsr wait

again:		bra again

