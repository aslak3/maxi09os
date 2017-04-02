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

list:		clrb			; long mode flag
		lda ,y+			; get type
		cmpa #4			; option code?
		bne startlist		; carry on
		ldb ,y+			; get option
startlist:	ldx currenttask
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

; print the name for the dirent in y, option is in b

putdirentname:	pshs a,b,x,y
		cmpb #'l
		beq 2$
1$:		ldx defaultio
		leay MINIXDE_NAME,y
		lbsr putstr
		ldy #newlinemsg
		lbsr putstr
		puls a,b,x,y
		rts
2$:		ldd MINIXDE_INODENO,y	; get inode number
		lbsr summariseinode
		bra 1$

dirtype:	.ascii 'd'
filetype:	.ascii 'f'

summariseinode:	pshs a,b,x,y
		ldx rootsuperblock
		leas -MINIXIN_SIZE,s
		tfr s,y
		lbsr getinode
		ldx defaultio
		lda MINIXIN_MODE,y	; load high byte of type/mode
		anda #MODE_TYPE_MASK
		cmpa #MODE_DIR
		beq showdir
		cmpa #MODE_REGULAR
		beq showfile
		lda #'-

gottype:	lbsr syswrite
		lda #ASC_SP
		lbsr syswrite

		lda MINIXIN_NLINKS,y
		lbsr putbyte
		lda #ASC_SP
		lbsr syswrite

		ldd MINIXIN_UID,y
		lbsr putword
		lda #'/
		lbsr syswrite
		lda MINIXIN_GID,y
		lbsr putbyte
		lda #ASC_SP
		lbsr syswrite

		ldd MINIXIN_LENGTH,y
		lbsr putword
		ldd MINIXIN_LENGTH+2,y
		lbsr putword
		lda #ASC_SP
		lbsr syswrite

		leas MINIXIN_SIZE,s
		puls a,b,x,y
		rts

showdir:	lda #'d
		bra gottype
showfile:	lda #'f
		bra gottype
	
; type "foo" - type the file to the output device

type:		lda ,y+			; get type
		cmpa #3			; string?
		lbne parserfail		; validation error
		tfr y,u			; get the filename

		lbsr openfile		; open the file
		lbne notfound		; not found error?
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
		setzero
		rts

; cd "foo" - type the file to the output device

cd:		lda ,y+			; get type
		cmpa #3			; string?
		lbne parserfail		; validation error
		tfr y,u			; get the filename

		lbsr changecwd		; change the current working dir
		lbne notadir		; not a directory

		rts

; failure message branches

general:	lda #ERR_GENERAL
		bra showerror
parserfail:	lda #ERR_PARSER_FAIL
		bra showerror
notadir:	lda #ERR_NOT_A_DIR
		bra showerror
notfound:	lda #ERR_NOT_FOUND
		bra showerror
internal:	lda #ERR_INTERNAL
		bra showerror

showerror:	ldx defaultio		; get io channel
		lbsr geterrorstr	; get error message from a into y
		lbsr putstr		; print it out
		ldy #newlinemsg		; add a new line
		lbsr putstr		; yep, there it is
		setnotzero		; set failed
		rts	

; built in commands

listcz:		.asciz 'list'
typecz:		.asciz 'type'
cdcz:		.asciz 'cd'

commandarray:	.word listcz
		.word list

		.word typecz
		.word type

		.word cdcz
		.word cd

		.word 0x0000
