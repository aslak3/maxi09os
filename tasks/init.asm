; our init task

		.include 'include/system.inc'
		.include 'include/debug.inc'
		.include 'include/hardware.inc'
		.include 'include/version.inc'

		.globl sysopen
		.globl sysclose
		.globl syscontrol
		.globl sysread
		.globl syswrite
		.globl mountminix
		.globl rootsuperblock
		.globl putstr
		.globl currenttask
		.globl createtask
		.globl wait

		.globl _timertask
		.globl _echotask
		.globl _shellstart
		
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
shell1taskname:	.asciz 'shellcon2'
shell2taskname:	.asciz 'shellcon3'
shell3taskname:	.asciz 'shelluart0'

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

; open the init io device, saving it in the variable and in x

openinitio:	pshs a,b,x
		ldx #initioz		; device
		lda initiounit		; unit
		ldb initiobaud		; baud rate
		lbsr sysopen
		stx initiodevice
		puls a,b,x
		rts

; close the init io device

closeinitio:	pshs x
		ldx initiodevice	; get the init io device
		lbsr sysclose		; close it
		ldx #0			; now it needs ...
		stx initiodevice	; ... to be cleared to zero
		puls x
		rts

; output the string in y to the init io device

writeinitstr:	pshs x
		ldx initiodevice	; get the init io device
		lbsr putstr		; output the string
		puls x
		rts		


initstartedz:	.asciz '\r\n\r\nInit started, build _BUILD_\r\n'
rootmountedz:	.asciz 'Root mounted\r\n'

_init::		debug ^'Init started',DEBUG_GENERAL

		lbsr openinitio		; open the init io channel

		ldy #initstartedz	; output a short greeting ...
		lbsr writeinitstr	; ... on the init io channel

		lbsr mountroot		; mount the root device

		ldy #rootmountedz	; output the fact that root's mounted
		lbsr writeinitstr	; ... on the init io channel

		lbsr closeinitio	; close the init io channel

		ldx currenttask		; get init's task struct
		ldy #1			; root inode is 0001
		sty TASK_CWD_INODENO,x	; this is inherited down the chain

		ldx #_timertask		; now start the timer task
		ldy #timertaskname	; ... giving it a name
		ldu #0			; and no default io
		lbsr createtask		; it will open the io devices itself

		ldx #consolenamez
		lda #1
		clrb
		lbsr sysopen
		tfr x,u
		ldx #_echotask
		ldy #echo1taskname
		lbsr createtask

		ldx #consolenamez
		lda #2
		clrb
		lbsr sysopen
		tfr x,u
		ldx #_shellstart
		ldy #shell1taskname
		lbsr createtask

		ldx #consolenamez
		lda #3
		ldb #1			; big scroll mode
		lbsr sysopen
		tfr x,u
		ldx #_shellstart
		ldy #shell2taskname
		lbsr createtask

		ldx #uartnamez
		lda #0
		ldb #B19200
		lbsr sysopen
		tfr x,u
		ldx #_shellstart
		ldy #shell3taskname
		lbsr createtask

;		ldx #uartnamez
;		lda #2
;		ldb #B19200
;		lbsr sysopen
;		tfr x,u
;		ldx #shellstart
;		ldy #shell4taskname
;		lbsr createtask

		clra			; wait on a signal that will ...
		lbsr wait		; ... never arrive

again:		bra again		; we should never reach here
