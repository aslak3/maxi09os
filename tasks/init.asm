; our init task

		.include '../include/system.inc'
		.include '../include/debug.inc'
		.include '../include/hardware.inc'

		.area RAM

rootdevice::	.rmb 2			; the open root device
rootsuperblock::.rmb 2			; the superblock handle

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

rootdevnamez:	.asciz 'ide'
rootunit:	.rmb 01

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

init::		debug ^'Init started',DEBUG_GENERAL

		lbsr mountroot		; mount the root device

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

;		ldx #sertermtask
;		ldy #sertermtaskname
;		ldu #0
;		lbsr createtask

		ldx #uartnamez
		lda #1
		ldb #B19200
		lbsr sysopen
		tfr x,u
		ldx #echotask
		ldy #echo3taskname
		lbsr createtask

		ldx #uartnamez
		lda #0
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

