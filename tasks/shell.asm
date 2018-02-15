; shell task

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/minix.inc'
		.include 'include/ascii.inc'
		.include 'include/debug.inc'

		.globl changecwd
		.globl currenttask
		.globl defaultio
		.globl geterrorstr
		.globl getinode
		.globl opencwd
		.globl getnextdirent
		.globl readfile
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
		.globl getchars
		.globl memoryalloc
		.globl memoryfree
		.globl putchardefio
		.globl putworddefio
		.globl putlabbdefio
		.globl putlabwdefio
		.globl forbid
		.globl permit

		.globl _newlinez

; state block, allocated memory available via TASK_USERDATA

structstart	0
member		SHELL_INPUT,256
member		SHELL_PARAMS,100
member		SHELL_DIRENT,MINIXDE_SIZE
structend	SHELL_SIZE

; getrun constants

; commands

COM_NULL	.equ 0     		; Does nothing, replies REP_NULL
COM_GET		.equ 1			; Filename\0.
COM_SIZE	.equ 2			; Filename\0.

; replies

REP_NULL 	.equ 0			; Empty.
REP_GET_DATA 	.equ 1			; Size, data.
REP_NOT_FOUND	.equ 2         		; Empty.
REP_BAD_COMMAND	.equ 3       		; Empty.
REP_TOO_BIG 	.equ 4			; Empty.

		.area ROM

promptz:	.asciz 'Command > '
commnotfoundz:	.asciz 'Command not found\r\n'
transuartz:	.asciz 'uart'

_shellstart::	ldx #SHELL_SIZE		; how many bytes do we need?
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
		bne nobuiltinmatch	; if no matches, read from disk
		jsr ,x			; run the subroutine
		bra shellloop		; back to the top of the shell loop

nobuiltinmatch:	bsr notbuiltin		; run the no command handler as a sub
		bra shellloop		; back to the top of the shell loop

notbuiltin:	tfr y,u			; get the commandline
		lbsr openfile		; open the file
		bne nofile		; no such filename?
1$:		tst ,y+			; move to the end of the filename
		bne 1$			; keep moving on?

		lbsr typeopenfile	; get the type of opened thing
		cmpa #MODE_REGULAR	; see if it is a normal file 
		lbne notregularfile	; error out of not a normal file
		lbsr readfile		; read file into y open file
		lbsr closefile		; we can close the file now

		ldx defaultio		; get default io
		tfr y,u			; save the external sub addr

		lbsr runsub		; run the subroutine, saving u

		tfr u,x			; restore the memory pointer
		lbsr memoryfree		; free the memory

2$:		rts

nofile:		ldy #commnotfoundz	; no externl file called that
		lbsr putstrdefio	; print the error message

		rts			; back to the top of the shell loop

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
		bne 2$			; end of "file", so out we go
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
		ldy #_newlinez		; and a we need ...
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
		beq 2$			; deal withi it by sending cr,lr
		lbsr syswrite		; write to the output channel
		bra 1$			; look for more bytes
2$:		lda #ASC_CR		; output the cr
		lbsr syswrite		; ...
		lda #ASC_LF		; output the lf
		lbsr syswrite		; this does lf->cr,lf conversion
		bra 1$			; back for more
3$:		lbsr sysclose		; end of file, close whats in x
		setzero
		rts

; cd "foo" - type the file to the output device

cd:		lda ,y+			; get type
		cmpa #3			; string?
		lbne parserfail		; validation error
		tfr y,u			; get the filename

		ldx #0			; no file to close on cd
		lbsr changecwd		; change the current working dir
		lbne notdir		; not a directory

		rts

; xrun - read a xmodem transfer on port b into memory and run it as a
; subroutine

xrun:		leas -1,s		; grab a byte of stack

		lda ,y+			; get type
		cmpa #2			; string?
		lbne parserfail		; validation error
		ldx ,y+			; get the size of the download

		lbsr memoryalloc	; get the memory
		tfr x,y			; save the address for copying
		tfr x,u			; save the starting address for jsr

		ldx #transuartz		; uart device name
		lda #1			; port b
		ldb #B19200		; set the baudrate
		lbsr sysopen		; open the port for the transfer

		lda #ASC_NAK		; ask for a start
		lbsr putchar		; ask sender to start sending

blockloop:	lbsr getchar		; get header byte
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
		ldy #_newlinez		; clean up the hashes ...
		lbsr putstr		; ... with a newline
		lbsr runsub		; run the subroutine

		ldx defaultio		; get the io channel
		lbsr putbyte		; output the resultant a register
		ldy #_newlinez		; and ...
		lbsr putstr		; ... a newline

		tsta			; 0 in a will indicate succes

xrunout:	tfr u,x			; restore the memory block
		lbsr memoryfree		; free the memory block

		leas 1,s		; fix up stack
		rts

xrunerror:	lbsr sysclose		; close the xmodem port

		setnotzero
		bra xrunout

; getrun - read a file transfer on port b into memory and run it as a
; subroutine

getrun:		leas -2,s		; two bytes for size

		lda ,y+			; get type
		cmpa #3			; string?
		lbne parserfail		; validation error
		tfr y,u			; get the filename

		ldx #transuartz		; uart device name
		lda #1			; port b
		ldb #B19200		; set the baudrate
		lbsr sysopen		; open the port for the transfer

		lda #COM_GET		; command byte
		lbsr putchar		; send it

		debugreg ^'Command sent: ',DEBUG_TASK_USER,DEBUG_REG_A

		tfr u,y			; get the filename
		lbsr putstr		; send the filename
		clra			; we need a null
		lbsr putchar		; send it

		debug ^'Filename sent',DEBUG_TASK_USER

		lbsr getchar		; we need the response

		debugreg ^'Got response: ',DEBUG_TASK_USER,DEBUG_REG_A

		cmpa #REP_GET_DATA	; looking for the file data
		lbne getrunerror	; if not, error path

		lbsr getchar		; now the filesize, high first
		sta ,s			; save the high byte
		lbsr getchar		; now the low half of the size
		sta 1,s			; save the low byte

		tfr x,u			; save the serial port device
		ldx ,s			; get the filesize again off stack

		debugreg ^'File size: ',DEBUG_TASK_USER,DEBUG_REG_X

		lbsr memoryalloc	; get the memory

		debugreg ^'Got memory: ',DEBUG_TASK_USER,DEBUG_REG_X

		exg x,u			; u now memory, x now device
		ldy ,s			; get the size again into y
		stu ,s			; save the start of the block

		lbsr forbid

block:		debug ^'Doing a block',DEBUG_TASK_USER

;		clra			; send a zero
;		lbsr putchar		; any byte will do

;		ldb #0			; 64 bytes per block
1$:		lbsr getchar		; get the byte
		sta ,u+			; save the file byte
		leay -1,y		; dec overall count
		beq endfile		; end of file
;		decb			; dec the inblock count
;		beq endblock		; end block?
		bra 1$			; back for another byte

;endblock:	bra block

endfile:	debug ^'Got the file bytes',DEBUG_TASK_USER

		lbsr permit

		ldu ,s			; get subroutine address

		lbsr sysclose		; we are done with the serial port

		ldx defaultio		; get the io channel for the task

		debug ^'About to run the sub',DEBUG_TASK_USER

		lbsr runsub		; run the subroutine

		debugreg ^'RTS with A: ',DEBUG_TASK_USER,DEBUG_REG_A

		tfr u,x			; now restore the subroutine addr
		lbsr memoryfree		; now we can free the memory

		debug ^'Memory freed',DEBUG_TASK_USER

getrunout:	leas 2,s		; fixup stack
		rts

getrunerror:	lbsr sysclose		; close the uart
		bra getrunout		; cleanup

runsub:		pshs x,y,u
		jsr ,u			; run the recieved file as a sub
		puls x,y,u
		rts

; failure message branches

parserfail:	lda #ERR_PARSER_FAIL
		ldx #0
		bra showerror

general:	lda #ERR_GENERAL
		bra showerror
notdir:		lda #ERR_NOT_DIR
		bra showerror
notregularfile:	lda #ERR_NOT_REGULAR
		bra showerror
notfound:	lda #ERR_NOT_FOUND
		bra showerror
internal:	lda #ERR_INTERNAL
		bra showerror

showerror:	cmpx #0			; file to close?
		beq 1$			; skip close of x
		lbsr sysclose		; close the file in x
1$:		ldx defaultio		; get io channel
		lbsr geterrorstr	; get error message from a into y
		lbsr putstr		; print it out
		ldy #_newlinez		; add a new line
		lbsr putstr		; yep, there it is
		setnotzero		; set failed
		rts

; built in commands

listcz:		.asciz 'list'
typecz:		.asciz 'type'
cdcz:		.asciz 'cd'
xruncz:		.asciz 'xrun'
getruncz:	.asciz 'getrun'

commandarray:	.word listcz
		.word list

		.word typecz
		.word type

		.word cdcz
		.word cd

		.word xruncz
		.word xrun

		.word getruncz
		.word getrun

		.word 0x0000
