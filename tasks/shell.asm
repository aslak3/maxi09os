; shell task

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/minix.inc'
		.include 'include/ascii.inc'

		.globl newlinez
		.globl changecwd
		.globl currenttask
		.globl defaultio
		.globl geterrorstr
		.globl getinode
		.globl opencwd
		.globl getnextdirent
		.globl rootsuperblock
		.globl typeopenfile
		.globl getstr
		.globl memoryalloc
		.globl openfile
		.globl closefile
		.globl parseinput
		.globl putbyte
		.globl putstr
		.globl putstrdefio
		.globl putword
		.globl strmatcharray
		.globl sysopen
		.globl sysclose
		.globl sysread
		.globl syswrite
		.globl getchar
		.globl putchar
		.globl memoryalloc
		.globl memoryfree
		.globl putchardefio
		.globl putworddefio

structstart	0
member		SHELL_INPUT,256
member		SHELL_PARAMS,100
member		SHELL_DIRENT,MINIXDE_SIZE
structend	SHELL_SIZE

		.area ROM

promptz:	.asciz 'Command > '
commnotfoundz:	.asciz 'Command not found\r\n'

shellstart::	ldx #SHELL_SIZE		; how many bytes do we need?
		lbsr memoryalloc	; allocate them
		tfr x,u			; u is the user data pointer
		ldx currenttask		; get the current task
		stu TASK_USERDATA,x	; save the user memory in task

shellloop:	ldx currenttask		; get current task. needed for u
		ldu TASK_USERDATA,x	; get task datablock pointer
		ldx defaultio		; defautl io used by some subs

		ldy #promptz		; output the prompt
		lbsr putstr		; "> " or something similar

		leay SHELL_INPUT,u	; setup the buffer to get it
		lbsr getstr		; get the command input

		leax SHELL_INPUT,u	; get input back
		leay SHELL_PARAMS,u	; setup output param stream
		lbsr parseinput		; parse into y, also makrs cmd end

		ldu #commandarray	; start at the start of the table
		lbsr strmatcharray	; try to match the string
		bne notbuiltin		; if no matches, read from disk
		jsr ,x			; run the subroutine
		bra shellloop		; back to the top of the shell loop

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
		bra shellloop		; back to the top of the shell loop

; COMMANDS

; list directory

list:		clrb			; long mode flag
		lda ,y+			; get type
		cmpa #4			; option code?
		bne startlist		; carry on
		ldb ,y+			; get option
startlist:	ldx currenttask		; get running task
		ldu TASK_USERDATA,x	; get space for dirent
		leay SHELL_DIRENT,u	; dirent is in there
		lbsr opencwd		; open the current directory into x
1$:		lbsr getnextdirent	; get the filename
		tst MINIXDE_NAME,y	; is filename 0-length?
		beq 2$			; if it is then we are finished
		lbsr putdirentname	; otherwise output all details
		bra 1$			; and go to the next name
2$:		lbsr closefile		; close the directory
		rts

; print the name for the dirent in y, option is in b

putdirentname:	pshs a,b,x,y
		cmpb #'l		; long mode listing set?
		beq 2$			; yes? summarise the inode
1$:		ldx defaultio		; get default io channel for shell
		leay MINIXDE_NAME,y	; get the filename from direent y
		lbsr putstr		; output the filename
		ldy #newlinez		; and a we need ...
		lbsr putstr		; ... a newline
		puls a,b,x,y
		rts
2$:		ldd MINIXDE_INODENO,y	; get inode number
		lbsr summariseinode	; sumarise the inode
		bra 1$

; file mode characters to show the type of file - todo: more types

dirtype:	.ascii 'd'
filetype:	.ascii 'f'

; summarise the inode in d, puts an inode on the stack

summariseinode:	pshs a,b,x,y
		ldx rootsuperblock	; get the mounted superblock
		leas -MINIXIN_SIZE,s	; make about 32 bytes on the stack
		tfr s,y			; this is the memory pointer ...
		lbsr getinode		; ... for the inode to be read into
		ldx defaultio		; get the default io channel
		lda MINIXIN_MODE,y	; load high byte of type/mode
		anda #MODE_TYPE_MASK	; mask out all but the file type
		cmpa #MODE_DIR		; compare it with directory type
		beq showdir		; show 'd'
		cmpa #MODE_REGULAR	; compare it with regular file type
		beq showfile		; show 'f'
		lda #'-			; show unknown type for others

gottype:	lbsr syswrite		; show the type letter
		lda #ASC_SP		; add a spare ...
		lbsr syswrite		; after the type letter

		lda MINIXIN_NLINKS,y	; get the number of hard links
		lbsr putbyte		; put that as 2 hex digits
		lda #ASC_SP		; and a space ...
		lbsr syswrite		; ... after it

		ldd MINIXIN_UID,y	; get the user id
		lbsr putword		; output as a word (4 hex digits)
		lda #'/			; and a slash ...
		lbsr syswrite		; to act as a seperator
		lda MINIXIN_GID,y	; get the group id
		lbsr putbyte		; output it as a byte
		lda #ASC_SP		; and a space ...
		lbsr syswrite		; ... after it

		ldd MINIXIN_LENGTH,y	; get the high word for the length
		lbsr putword		; and output as a word
		ldd MINIXIN_LENGTH+2,y	; get the low word for the length
		lbsr putword		; and output it as a word
		lda #ASC_SP		; yes, it's ...
		lbsr syswrite		; ... another space

		leas MINIXIN_SIZE,s	; shrink the stack back
		puls a,b,x,y
		rts

showdir:	lda #'d			; little tail for directory
		bra gottype		; back to main path
showfile:	lda #'f			; lttile tail for file
		bra gottype		; back to main path
	
; type "foo" - type the file to the output device

type:		lda ,y+			; get type
		cmpa #3			; string?
		lbne parserfail		; validation error
		tfr y,u			; get the filename

		lbsr openfile		; open the file
		lbne notfound		; not found error?
		lbsr typeopenfile	; get the type of opened thing
		cmpa #MODE_REGULAR	; see if it is a normal file
		lbne notregularfile	; error out of not a normal file
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
		lbne notdir		; not a directory

		rts

; failure message branches

general:	lda #ERR_GENERAL
		bra showerror
parserfail:	lda #ERR_PARSER_FAIL
		bra showerror
notdir:		lda #ERR_NOT_DIR
		bra showerror
notregularfile:	lda #ERR_NOT_REGULAR
		bra showerror
notfound:	lda #ERR_NOT_FOUND
		bra showerror
internal:	lda #ERR_INTERNAL
		bra showerror

showerror:	ldx defaultio		; get io channel
		lbsr geterrorstr	; get error message from a into y
		lbsr putstr		; print it out
		ldy #newlinez		; add a new line
		lbsr putstr		; yep, there it is
		setnotzero		; set failed
		rts	

; xrun - read a xmodem transfer on port b into memory and run it as a
; subroutine

uartz:		.asciz 'uart'

xrun:		leas -1,s		; grab a byte of stack

		lda ,y+			; get type
		cmpa #2			; string?
		lbne parserfail		; validation error
		ldx ,y+			; get the size of the download

		lbsr memoryalloc	; get the memory
		tfr x,y			; save the address for copying
		tfr x,u			; save the starting address for jsr

		ldx #uartz		; uart device name
		lda #1			; port b
		ldb #B19200		; set the baudrate
		lbsr sysopen		; open the port for the transfer

		lda #ASC_NAK		; ask for a start
		lbsr putchar		; ask sender to start sending

blockloop:	
		lbsr getchar		; get header byte	
		cmpa #ASC_EOT		; eot for end of file
		beq xrunrun		; if so then we run
		cmpa #ASC_SOH		; soh for start of block
		bne xrunerror		; if not then this is an error

		lbsr getchar		; blocks so far
		lbsr getchar		; 255 less blocks so far

		clr ,s			; clear the checksum

		ldb #128		; 128 bytes per block

byteloop:	lbsr getchar		; get the byte for th efile
		sta ,y+			; store the byte
		adda ,s			; add the received byte the checksum
		sta ,s			; store the checksum on each byte
		decb			; decrement our byte counter
		bne byteloop		; see if there are more bytes
		
		lbsr getchar		; get the checksum from sender
		cmpa ,s			; check it against the one we made
		bne blockbad		; if no good, handle it

		lda #ASC_ACK		; if good, then ACK the block
		lbsr putchar		; send the ACK

		lda #'#			; output a progress marker
		lbsr putchardefio	; on the shell device

		bra blockloop		; get more blocks

blockbad:	lda #ASC_NAK		; oh no, it was bad
		lbsr putchar		; send a NAK; sender resends block

		leay -0x80,y		; move back to start of the block
		
		bra blockloop		; try to get the same block again

xrunrun:	lda #ASC_ACK		; at end of file ...
		lbsr putchar		; ... ack the file

		lbsr sysclose		; close the 2nd uart port

		ldx defaultio		; load the io channel for x
		ldy #newlinez		; clean up the hashes ...
		lbsr putstr		; ... with a newline
		jsr ,u			; run the recieved file as a sub

		ldx defaultio		; get the io channel
		lbsr putbyte		; output the resultant a register
		ldy #newlinez		; and ...
		lbsr putstr		; ... a newline

		tsta			; 0 in a will indicate succes

xrunout:	tfr u,x			; restore the memory block
		lbsr memoryfree		; free the memory block

		leas 1,s		; fix up stack
		rts

xrunerror:	lbsr sysclose		; close the xmodem port

		setnotzero
		bra xrunout

; built in commands

listcz:		.asciz 'list'
typecz:		.asciz 'type'
cdcz:		.asciz 'cd'
xruncz:		.asciz 'xrun'

commandarray:	.word listcz
		.word list

		.word typecz
		.word type

		.word cdcz
		.word cd

		.word xruncz
		.word xrun

		.word 0x0000
