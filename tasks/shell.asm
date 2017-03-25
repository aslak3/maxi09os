; shell task

		.include '../include/system.inc'
		.include '../include/minix.inc'
		.include '../include/ascii.inc'

structstart	0
member		SHELL_INPUT,256
member		SHELL_PARAMS,100
member		SHELL_DIRENT,MINIXDE_SIZE
structend	SHELL_SIZE

		.area ROM

promptz:	.asciz '\r\nCommand > '
commnotfoundz:	.asciz 'Command not found\r\n'

shellstart::	ldx #SHELL_SIZE
		lbsr memoryalloc
		tfr x,u
		ldx currenttask
		stu TASK_USERDATA,x	; save the user memory pointer

shellloop:	ldx currenttask		; get current task. needed for u
		ldu TASK_USERDATA,x	; get task datablock pointer
		ldx defaultio		; defautl io used by some subs

		ldy #promptz
		lbsr putstr

		leay SHELL_INPUT,u
		lbsr getstr
		ldy #newlinemsg
		lbsr putstr

		leax SHELL_INPUT,u	; get input back
		leay SHELL_PARAMS,u	; setup output param stream
		lbsr parseinput		; parse into y, also makrs cmd end

		ldu #commandarray
		lbsr strmatcharray	; try to match the string
		bne notbuiltin
		jsr ,x			; run the subroutine
		bra shellloop

notbuiltin:	tfr y,u			; get the commandline
		lbsr openfile		; open the file
		bne nofile		; no such filename?
1$:		tst ,y+			; move to the end of the filename
		bne 1$			; keep moving on?
		; todo: read file in and run it as a subroutine
		lbsr closefile		; close it
		bra shellloop

nofile:		ldy #commnotfoundz	; no externl file called that
		lbsr putstrdefio	; print the error message
		bra shellloop

; COMMANDS

; list directory

list:		ldx currenttask
		ldu TASK_USERDATA,x	; get space for dirent
		leay SHELL_DIRENT,u
		lbsr opencwd		; open the current directory into x
1$:		lbsr getnextdirent
		tst MINIXDE_NAME,y
		beq 2$
		lbsr putdirentname
		bra 1$
2$:		lbsr closefile		; close the directory
		rts

; print the name for the dirent in y

putdirentname:	pshs x,y
		ldx defaultio
		leay MINIXDE_NAME,y
		lbsr putstr
		ldy #newlinemsg
		lbsr putstr
		puls x,y
		rts
		
; list with detailed info

listlong:	ldy #listlongcz
		lbsr putstrdefio
		rts

; type "foo" - type the file to the output device

type:		lda ,y+			; get type
		cmpa #3			; string?
		lbne badparams		; validation error
		tfr y,u			; get the filename

		lbsr openfile		; open the file
		lbne commfailed
		tfr x,y			; y now has the file device
		ldx defaultio		; has the default io channel
1$:		exg x,y			; x now has the file
		lbsr sysread		; get the byte from the file
		bne 3$			; finished with file
		exg x,y			; x now has the terminal
		cmpa #ASC_LF		; check for \n
		beq 2$			; deal withi it by sending \r\n
		lbsr syswrite		; write to the output channel
		bra 1$
2$:		lda #ASC_CR
		lbsr syswrite
		lda #ASC_LF
		lbsr syswrite
		bra 1$
3$:		lbsr sysclose
		rts

; failure message branches

badparamsz:	.asciz 'Bad parameters\r\n'

badparams:	ldy #badparamsz
		lbsr putstrdefio
		rts

commfailedz:	.asciz 'Command failed\r\n'

commfailed:	ldy #commfailedz
		lbsr putstrdefio
		rts

generalerror:	

; built in commands

listcz:		.asciz 'list'
listlongcz:	.asciz 'listlong'
typecz:		.asciz 'type'

commandarray:	.word listcz
		.word list

		.word listlongcz
		.word listlong

		.word typecz
		.word type

		.word 0x0000
