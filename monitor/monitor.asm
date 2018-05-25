		.include 'include/system.inc'

		.globl memoryavail
		.globl defaultio
		.globl findinode
		.globl forbid
		.globl permit
		.globl getchars
		.globl unmountminix
		.globl mountminix
		.globl getinode
		.globl copystr
		.globl parseinput
		.globl strcmp
		.globl idletask
		.globl openfile
		.globl printableasc
		.globl getstr
		.globl putbyte
		.globl putlabbb
		.globl putlabbdefio
		.globl putlabb
		.globl putlabbdefio
		.globl putlabw
		.globl putlabwdefio
		.globl putstr
		.globl putstrdefio
		.globl putword
		.globl readytasks
		.globl statfile
		.globl sysclose
		.globl syscontrol
		.globl sysopen
		.globl sysread
		.globl sysseek
		.globl syswrite
		.globl waitingtasks
		.globl disassentry

		.globl _newlinez

		.globl l_RAM

; the monitor is not reenterant - these are globals

		.area RAM

iodevice:	.rmb 2
inputbuffer:	.rmb 80
parambuffer:	.rmb 100
dumppointer:	.rmb 2
dumpcounter:	.rmb 2
taskslong:	.rmb 1

		.area ROM

greetz:		.asciz '\r\nEntered monitor\r\n\r\n'
promptz:	.asciz '> '
commfailedz:	.asciz 'Command failed\r\n'
nosuchz:	.asciz 'No such command\r\n'
resultz:	.asciz 'Result: '

quitz:		.asciz 'quit'
leavingmonz:	.asciz '\r\nLeaving moinitor\r\n\r\n'

; monitor entry point

_monitorstart::	lbsr forbid		; disable task switching

		ldy #greetz		; say hello
		lbsr putstr		; hello!

		stx iodevice		; save the io device we are using

mainloop:	ldx iodevice		; get io device

		ldy #promptz		; '>' etc
		lbsr putstr		; output that
		ldy #inputbuffer	; now we need a command
		lbsr getstr		; get the command (waiting as needed)

		; parambuffer contains:
		;   command followed by null
		;   followed by 01 (byte) 02 (word) 03 (string with null)
		;   followed by a null

		ldx #inputbuffer	; now parse the input buffer
		ldy #parambuffer	; into the parameter buffer
		lbsr parseinput		; do the parse to extract stuff

		ldx #quitz
		lbsr strcmp
		beq quitcommand

startarray:	ldu #commandarray	; setup the command pointer
nextcommand:	ldx ,u++		; get the command name
		beq nosuchcommand	; end of command list?
		lbsr strcmp		; compare the command with the list
		bne nomatch		; no match? check next one
skipcommand:	tst ,y+			; advance through the parambuffer
		bne skipcommand		; until we reach end of command
		jsr [,u]		; jump to subroutine
		bne commanderror	; error check for zero
		bra mainloop		; back to top

quitcommand:	ldx iodevice		; get current io device
		ldy #leavingmonz	; tell user they are leaving monitor
		lbsr putstr
		lbsr permit		; enable multitasking
		rti			; leave the monitor

nomatch:	ldx ,u++		; need to advance past sub pointer
		bra nextcommand		; before checking next command

commanderror:	ldy #commfailedz	; command failed error message
		lbsr putstrdefio	; show error
		bra mainloop

nosuchcommand:	ldy #nosuchz		; no such command
		lbsr putstrdefio	; show error
		bra mainloop

; general error handler branch for commands that fail

generalerror:	lda #1			; set error state
		rts			; exit command sub

;;; COMMANDS ;;;
;
; on entry to command sub, y contains the first parameter type

; dump AAAA LLLL - dumps from AAAA, LLLL bytes
;
; C000  48 65 6C 6C 6F 2C 20 74  68 69 73 20 69 73 20 61  [Hello, this is a]

dump:		lda ,y+			; get the type
		cmpa #2			; is it a word?
		lbne generalerror	; validation error
		ldd ,y++		; start address
		andb #0xf0		; round to nearest 16
		std dumppointer		; store it in the variable
		lda ,y+			; get the type
		cmpa #2			; is it a word?
		lbne generalerror	; validation error
		ldd ,y++		; length/count of bytes
		andb #0xf0		; also rounded
		std dumpcounter		; store it in the variable

		ldx defaultio		; io device for the monitor

dumpnextrow:	ldd dumppointer		; get address of this row
		lbsr putword		; print the address into the buffer
		lda #0x20		; space
		lbsr syswrite		; " "
		lbsr syswrite		; " "

; hex version

		ldy dumppointer		; points at the start of the row
		ldb #0			; counts across 16 bytes

hexbyteloop:	cmpb #0x08		; for pretty ness...
		bne noextraspace	; add a space after 8 bytes
		lda #0x20		; space
		lbsr syswrite
noextraspace:	lda b,y			; actually read the byte from memory
		lbsr putbyte		; convert it to ascii
		lda #0x20		; space
		lbsr syswrite		; add a space between each byte
		incb			; incrememnt offset
		cmpb #0x10		; 16 bytes per row
		bne hexbyteloop		; and do the next byte

		lda #0x20		; spaces
		lbsr syswrite		; add it in
		lda #0x5b		; opening [
		lbsr syswrite		; add it in

; ascii version

		ldy dumppointer		; reset back to the start of the row
		ldb #0			; counts across 16 bytes

ascbyteloop:	lda b,y			; get the byte from memory
		lbsr printableasc	; nonprintable to a dot
		lbsr syswrite		; add it in
		incb			; increment offset
		cmpb #0x10		; 16 bytes per row
		bne ascbyteloop		; and do the next byte

		lda #0x5d		; closing ]
		lbsr syswrite		; add it in

		ldy #_newlinez		; newline
		lbsr putstr		; output it

; move onto the the next row

		ldy dumppointer		; load the pointer back in
		leay 0x10,y		; add 0x10
		sty dumppointer		; store it back
		ldy dumpcounter		; loead the remaning byte counter
		leay -0x10,y		; subtract 0x10
		sty dumpcounter		; store it back

		bne dumpnextrow		; more rows?
		clra			; no error
		rts

; write AAAA BB WWWW "STRING" - write bytes, words or strings

write:		lda ,y+			; get the type
		cmpa #2			; is it a word?
		lbne generalerror	; validation error
		ldx ,y++		; start address
nextwrite:	lda ,y+			; get the type
		beq writememoryout	; that's the end of the byte list
		cmpa #1			; is it a byte?
		beq storebyte		; yes, so process bytes
		cmpa #2
		beq storeword		; same for words
		cmpa #3
		beq storestring		; same for strings
		tsta
		beq writememoryout	; null? we are done
		lbra generalerror	; otherwise its unknown, so bail

storebyte:	ldb ,y+			; get the byte to write
		stb ,x+			; and load it at memory x
		bra nextwrite		; back for more
storeword:	ldd ,y++		; get the word to write
		std, x++		; and load it
		bra nextwrite		; back for more
storestring:	lbsr copystr		; use the concatstr operation
		bra nextwrite		; ...it copies y->x
	
writememoryout:	clra			; clean exit
		rts

; parsetest BB WWWW "STRING" -A.... - test the parser by outputting what was parsed

bytefoundz:	.asciz 'byte: '
wordfoundz:	.asciz 'word: '
stringfoundz:	.asciz 'string: '
optionfoundz:	.asciz 'option: '

parsetest:	tfr y,u
		ldx defaultio

parsetestloop:	lda ,u+
		cmpa #1
		beq bytefound
		cmpa #2
		beq wordfound
		cmpa #3
		beq stringfound
		cmpa #4
		beq optionfound
		tsta
		beq parsetestout
		lbra generalerror

parsetestout:	clra
		rts

bytefound:	ldy #bytefoundz
		lbsr putstr
		lda ,u+
		lbsr putbyte
		ldy #_newlinez
		lbsr putstr
		bra parsetestloop

wordfound:	ldy #wordfoundz
		lbsr putstr
		ldd ,u++
		lbsr putword
		ldy #_newlinez
		lbsr putstr
		bra parsetestloop

stringfound:	ldy #stringfoundz
		lbsr putstr
		tfr u,y
		lbsr putstr
1$:		tst ,u+
		bne 1$
		ldy #_newlinez
		lbsr putstr
		bra parsetestloop		

optionfound:	ldy #optionfoundz
		lbsr putstr
		lda ,u+			; get next byte (the option char)
		lbsr syswrite		; write it out as char
		ldy #_newlinez		; now add a newline
		lbsr putstr
		bra parsetestloop	; back for more

; readbyte AAAA - reads the byte at AAAA and displays it

readbyte:	lda ,y+
		cmpa #2			; is it a word?
		lbne generalerror	; validation error
		ldy ,y			; get the address

		ldx defaultio		; some things to write to default io

		lda ,y			; get the byte from the address
		lbsr putbyte		; output the byte
		ldy #_newlinez		; and we need a newline
		lbsr putstr		; to tidy things up
		clra			; success
		rts

; readword AAAA - reads the word at AAAA and displays it

readword:	lda ,y+
		cmpa #2			; is it a word?
		lbne generalerror	; validation error
		ldy ,y			; get the address

		ldx defaultio		; some things to write to default io

		ldd ,y			; get the byte from the address
		lbsr putword		; output the word
		ldy #_newlinez		; and we need a newline
		lbsr putstr		; to tidy things up
		clra			; success
		rts

; memory - show the memory info

totalmemz:	.asciz 'Total: '
freememz:	.asciz 'Free: '
largestmemz:	.asciz 'Largest: '

memory:		ldx defaultio		; everything outputs on default io

		lda #AVAIL_TOTAL	; get the total memory
		lbsr memoryavail	; it will go in d
		ldy #totalmemz		; we will print a label too
		lbsr putlabw		; which also adds a newline

		lda #AVAIL_FREE		; get the free memory
		lbsr memoryavail	; ...
		ldy #freememz		; ...
		lbsr putlabw		; ,,,

		lda #AVAIL_LARGEST	; and the largest memory block
		lbsr memoryavail	; ...
		ldy #largestmemz	; ...
		lbsr putlabw		; ...

		clra
		rts

; debugmemory - show all memory blocks in the heap

blockstartz:	.asciz 'Start: '
blocknextz:	.asciz 'Next: '
blocklengthz:	.asciz 'Length: '
blockfreez:	.asciz 'Free: '

debugmemory:	ldx defaultio		; everything outputs to default io
		ldu #l_RAM		; start at the start of the heap

1$:		tfr u,d			; show the start
		ldy #blockstartz	; ...
		lbsr putlabw		; ...

		ldd MEM_NEXT,u		; show the next pointer
		ldy #blocknextz		; ...
		lbsr putlabw		; ...

		ldd MEM_LENGTH,u	; show the length
		ldy #blocklengthz	; ...
		lbsr putlabw		; ...

		lda MEM_FREE,u		; show free state
		ldy #blockfreez		; ...
		lbsr putlabb		; ...

		ldy #_newlinez		; and a new line
		lbsr putstr		; ...

		ldu MEM_NEXT,u		; get the next pointer
		bne 1$			; back for more if not at end

		clra
		rts

; tasks - shows all kinds of info about all the tasks in the system

readytasksz:	.asciz 'READY TASKS\r\n'
waitingtasksz:	.asciz 'WAITING TASKS\r\n'
idlerz:		.asciz 'IDLER\r\n'

tasks:		clr taskslong		; not in long mode by default
		lda ,y+			; get type
		cmpa #4			; looking for options
		bne 1$			; skip
		lda ,y+			; get option
		cmpa #'l		; look for long option
		bne 1$			; skip
		lda #1			; otherwise match, set long mode
		sta taskslong		; set long mode

1$:		ldy #readytasksz	; the heading for ready tasks
		lbsr putstrdefio	; show this heading in default io
		ldy #readytasks		; get the ready tasks list
		lbsr showtasklist	; show this list

		ldy #waitingtasksz	; the heading for the waiting tasks
		lbsr putstrdefio	; ...
		ldy #waitingtasks	; ...
		lbsr showtasklist	; ...

		ldy #idlerz		; the heading for the idle task
		lbsr putstrdefio	; output it
		ldx idletask		; get the idle task handle
		lbsr showtask		; show info about that task

		clra
		rts

showtasklist:	ldx LIST_HEAD,y		; get the first node
showtaskloop:	ldy NODE_NEXT,x		; get its following node
                beq endtasklist		; last node?
		lbsr showtask		; show info about task x
		ldx NODE_NEXT,x		; get the next one
		bra showtaskloop	; and back for more tasks
endtasklist:	ldy #_newlinez		; tidy up...
		lbsr putstrdefio	; ... with a new line

		rts

lchevronsz:	.asciz '<<<'
rchevronsz:	.asciz '>>> '
parentz:	.asciz 'Parent: '
defaultioz:	.asciz 'Default IO: '
cwdinodenoz:	.asciz 'CWD INode Number: '
initialpcz:	.asciz 'Initial PC: '
savedsz:	.asciz 'Saved S: '
sigallocz:	.asciz 'Sig Alloc: '
sigwaitz:	.asciz 'Sig Wait: '
sigrecvdz:	.asciz 'Sig Rcvd: '
dispatchcountz:	.asciz 'Dispatch Count: '

showtask:	pshs x
		tfr x,u			; u has the structure pointer

		ldx defaultio

		ldy #lchevronsz
		lbsr putstr
		leay TASK_NAME,u
		lbsr putstr
		ldy #rchevronsz
		lbsr putstr

		tfr u,d
		lbsr putword
		ldy #_newlinez
		lbsr putstr

		tst taskslong		; check for long mode
		beq 1$			; not long, so out we go now

		ldd TASK_PARENT,u
		ldy #parentz
		lbsr putlabw

		ldd TASK_DISPCOUNT,u
		ldy #dispatchcountz
		lbsr putlabw

		ldd TASK_DEF_IO,u
		ldy #defaultioz
		lbsr putlabw

		ldd TASK_CWD_INODENO,u
		ldy #cwdinodenoz
		lbsr putlabw

		ldd TASK_PC,u
		ldy #initialpcz
		lbsr putlabw

		ldd TASK_SP,u
		ldy #savedsz
		lbsr putlabw

		lda TASK_SIGALLOC,u
		ldy #sigallocz
		lbsr putlabbb

		lda TASK_SIGWAIT,u
		ldy #sigwaitz
		lbsr putlabbb

		lda TASK_SIGRECVD,u
		ldy #sigrecvdz
		lbsr putlabbb

		ldy TASK_SP,u
		lbsr taskregisters

1$:		puls x
		rts

disass:		lda ,y+			; get the type
		cmpa #2			; is it a word?
		lbne generalerror	; validation error
		ldu ,y++		; start address
		lda ,y+                 ; get the type
		cmpa #2                 ; is it a word?
		lbne generalerror       ; validation error
		ldx ,y++                ; instruction count

		lbsr disassentry	; do the disassembly

		rts

; shows the registers as they were when the monitor was entered

ccz:		.asciz 'CC: '
az:		.asciz '  A: '
bz:		.asciz '  B: '
dpz:		.asciz '  DP: '
xz:		.asciz '  X: '
yz:		.asciz '  Y: '
uz:		.asciz '  U: '
pcz:		.asciz '  PC: '

taskregisters:	pshs a,u

		tfr y,u

		ldy #ccz		; get the 'C: '
		lbsr putstr
		lda 0,u			; get the register value
		lbsr putbyte

		ldy #az			; same again
		lbsr putstr
		lda 1,u			; ...
		lbsr putbyte		; ...

		ldy #bz
		lbsr putstr
		lda 2,u
		lbsr putbyte

		ldy #dpz
		lbsr putstr
		lda 3,u
		lbsr putbyte

		ldy #xz
		lbsr putstr
		ldd 4,u
		lbsr putword

		ldy #yz
		lbsr putstr
		ldd 6,u
		lbsr putword

		ldy #uz
		lbsr putstr
		ldd 8,u
		lbsr putword

		ldy #pcz
		lbsr putstr
		ldd 10,u
		lbsr putword

		ldy #_newlinez
		lbsr putstr

		puls a,u

		rts

; task TTTT - show task TTTT

task:		lda ,y+			; get the type
		cmpa #2			; is it a word?
		lbne generalerror	; validation error
		ldx ,y++		; get the task hanlde

		lda #1
		sta taskslong		; always show long form
		lbsr showtask		; show that task

		rts

; sysopen "DEVICE" [AA [BB]] - open the DEVICE, unit AA extra param BB

dosysopen:	ldb ,y+			; get the type
		cmpb #3			; is it a string?
		lbne generalerror	; validation error

		tfr y,x			; save the device name

1$:		tst ,y+			; testing for nulls
		bne 1$			; keep advancing y to the end

		ldb ,y+			; get the type
		cmpb #1			; byte?
		bne 2$			; no unit, skip ahead
		lda, y+			; get the unit

		ldb ,y+			; get the type
		cmpb #1			; byte?
		bne 2$			; no extra param, skip ahead
		ldb, y+			; get the extra param (baud rate?)

2$:		lbsr sysopen		; do the oepn call

		tfr x,d			; we are printing x
		ldy #resultz		; print a nice label
		lbsr putlabwdefio	; print the device handle

		clra
		rts		

minixcomz:	.asciz 'minix'

; dominixopen MMMM IIII open the file, inode IIII in mounted fs MMMM

dominixopen:	
		lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; oh dear
		ldx ,y++		; get the mounted superblock

		lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; oops
		ldy ,y++		; get the inode number

		tfr y,u			; inode number inu
		tfr x,y			; device in y
		ldx #minixcomz		; always minix

		lbsr sysopen		; do the oepn call

		tfr x,d			; we are printing x
		ldy #resultz		; print a nice label
		lbsr putlabwdefio	; print the device handle

		clra
		rts		


; sysclose HHHH - close the device at HHHH

dosysclose:	ldb ,y+			; get the type
		cmpb #2			; is it a string?
		lbne generalerror	; validation error
		ldx ,y++		; get the device handle

		lbsr sysclose		; close it

		rts			; propogate the cc

; sysread HHHH - read a byte

dosysread:	lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldx ,y++		; get the device handle

		lbsr sysread		; do the read
		tfr cc,b		; save the conditions

		ldy #resultz		; get the label
		lbsr putlabbdefio	; print the byte read with label

		tfr b,cc		; get the sysread conditions
		rts			; return with them

; sysreadblock HHHH SSSS CC MMMM - read a block from sector SSS count CC
; into memory MMMM

dosysreadblk:	lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldx ,y++		; get the device handle

		lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldu ,y++		; get the sector offset

		lda ,y+			; get the type
		cmpa #1			; byte?
		lbne generalerror	; validation error
		lda ,y+			; get the count (a)

		ldb ,y+			; get the type
		cmpb #2			; word?
		lbne generalerror	; validation error
		ldy ,y++		; get the mmory address

		lbsr sysread

		rts

; syswrite HHHH BB - write a byte

dosyswrite:	lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldx ,y++		; get the device handle

		lda ,y+			; get the type
		cmpa #1			; word?
		lbne generalerror	; not either, so error
		lda ,y+			; get the byte to write

		lbsr syswrite		; do the write

		rts			; propogate control code

; syswriteblock HHHH SSSS CC MMMM - write a block

dosyswriteblk:	lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldx ,y++		; get the device handle

		lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldu ,y++		; get the sector offset

		lda ,y+			; get the type
		cmpa #1			; byte?
		lbne generalerror	; validation error
		lda ,y+			; get the count

		ldb ,y+			; get the type
		cmpb #2			; word?
		lbne generalerror	; validation error
		ldy ,y++		; get the mmory address

		lbsr syswrite

		rts

; sysseek HHHH PPPP - seek to PPPP

dosysseek:	lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldx ,y++		; get the device handle

		lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldy ,y++		; get the offset

		lbsr sysseek		; do the read
		rts			; return with the conditions

; syscontrol HHHH AA [MMMM] : do a control operation of device HHHH, command AA
; with block y

dosyscontrol:	ldb ,y+			; get the type
		cmpb #2			; word?
		lbne generalerror	; validation error
		ldx ,y++		; get the device handle

		ldb ,y+			; get the type
		cmpb #1			; byte?
		lbne generalerror
		lda ,y+			; get the command

		ldb ,y+			; get the type
		beq 1$			; end of stream, no address
		cmpb #2			; word?
		lbne generalerror	; validation error
		ldy ,y++		; get the control block

1$:		lbsr syscontrol		; do the write

		rts			; propogate control code

mntminix:	lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldx ,y++		; get the device handle

		lbsr mountminix		; mount the device

		tfr y,d			; we are printing y
		ldy #resultz		; print a nice label
		lbsr putlabwdefio	; print the device handle

		clra

		rts

unmntminix:	lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldx ,y++		; get the device handle

		lbsr unmountminix	; unmount the device

		rts

; getinode DDDD IIII YYYY

dogetinode:	lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldx ,y++		; get the device handle

		lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldu ,y++		; get the inode number

		lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldy ,y++		; get the memory address

		tfr u,d			; set the inode number

		lbsr getinode

		rts

; getchars DDDD LLLL MMMM

dogetchars:	lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldx ,y++		; get the device handle

		lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldu ,y++		; get the length

		lda ,y+			; get the type
		cmpa #2			; word?
		lbne generalerror	; validation error
		ldy ,y++		; get the memory address

		lbsr getchars

		rts

; findinode "filename"

dofindinode:	lda ,y+			; get the type
		cmpa #3			; word?
		lbne generalerror	; validation error

		tfr y,u			; filename in u

		lbsr findinode		; get the indoe in d

		ldy #resultz		; print a nice label
		lbsr putlabwdefio	; print the inode number

		clra

		rts

; openfile "filename"

doopenfile:	lda ,y+			; get the type
		cmpa #3			; word?
		lbne generalerror	; validation error
		tfr y,u			; filename needs to be in u

		lbsr openfile		; open the file

		tfr x,d			; save the handle in do for printing

		ldy #resultz		; print a nice label
		lbsr putlabwdefio	; print the device handle

		clra

		rts

; statfile "filename" MMMM

dostatfile:	lda ,y+			; get the type
		cmpa #3			; word?
		lbne generalerror	; validation error
		tfr y,u			; filename needs to be in u

1$:		tst ,y+			; testing for nulls
		bne 1$			; keep advancing y to the end

		lda ,y+			; get the type
		cmpa #2			; byte?
		lbne generalerror	; validation error
		ldy, y++		; get the memory
		
		lbsr statfile

		rts

; help or ? - shows some help text

helpz:		.ascii 'Low-level commands:\r\n'
		.ascii '  dump AAAA LLLL : dump from AAAA count LLLL bytes in hex\r\n'
		.ascii '  write AAAA BB WWWW "STRING" ... : write to AAAA bytes, words, strings\r\n'
		.ascii '  readbyte MMMM : read the byte at MMMM and display it\r\n'
		.ascii '  readword MMMM : read the word at MMMM and display it\r\n'
		.ascii 'System info commands:\r\n'
		.ascii '  tasks : show tasks\r\n'
		.ascii '  task TTTT : show the task TTTT\r\n'
		.ascii '  memory : show memory statistics\r\n'
		.ascii '  debugmemory : dump out each heap memory block\r\n'
		.ascii 'Device commands:\r\n'
		.ascii '  sysopen "DEVICE" [AA [BB]] : open DEVICE with optional params\r\n'
		.ascii '  sysclose HHHH : close the device at handle HHHH\r\n'
		.ascii '  sysread HHHH : read a byte from device HHHH\r\n'
		.ascii '  syswrite HHHH BB : write a byte BB to device HHHH\r\n'
		.ascii '  sysreadblock HHHH SSSS CC MMMM : read at SSSS, CC sectors to MMMM\r\n'
		.ascii '  syswriteblock HHHH SSSS CC MMMM : write at SSSS, CC sectors from MMMM\r\n'
		.ascii '  sysseek HHHH AAAA : seek to position AAAA\r\n'
		.ascii '  syscontrol HHHH CC [MMMM] : perform command CC with param block at MMMM\r\n'
		.ascii 'Other commands:\r\n'
		.ascii '  help or ? : this help\r\n'
		.ascii '  quit : quit monitor and resume task switching\r\n'
		.asciz '\r\n'

help:		ldx defaultio
		ldy #helpz		; and the help text
		lbsr putstr		; output the message
		clra			; we always suceed
		rts

; command names

helpcz:		.asciz 'help'
questioncz:	.asciz '?'
dumpcz:		.asciz 'dump'
writecz:	.asciz 'write'
parsetestcz:	.asciz 'parsetest'
readbytecz:	.asciz 'readbyte'
readwordcz:	.asciz 'readword'
memorycz:	.asciz 'memory'
debugmemorycz:	.asciz 'debugmemory'
taskscz:	.asciz 'tasks'
taskcz:		.asciz 'task'
disasscz:	.asciz 'disass'

dosysopencz:	.asciz 'sysopen'
dosysclosecz:	.asciz 'sysclose'
dosysreadcz:	.asciz 'sysread'
dosyswritecz:	.asciz 'syswrite'
dosysreadbcz:	.asciz 'sysreadblock'
dosyswritebcz:	.asciz 'syswriteblock'
dosysseekcz:	.asciz 'sysseek'
dosysctrlcz:	.asciz 'syscontrol'

dominixopencz:	.asciz 'minixopen'

mntminixcz:	.asciz 'mountminix'
unmntminixcz:	.asciz 'unmountminix'

dogetinodecz:	.asciz 'getinode'
dogetcharscz:	.asciz 'getchars'
dofindinodecz:	.asciz 'findinode'
doopenfilecz:	.asciz 'openfile'
dostatfilecz:	.asciz 'statfile'

; command array - a list of command name and subroutine addresses, ending
; in a null word

commandarray:	.word helpcz
		.word help
		.word questioncz
		.word help

		.word dumpcz
		.word dump

		.word writecz
		.word write

		.word parsetestcz
		.word parsetest

		.word readbytecz
		.word readbyte

		.word readwordcz
		.word readword

		.word memorycz
		.word memory

		.word debugmemorycz
		.word debugmemory

		.word taskscz
		.word tasks

		.word taskcz
		.word task

		.word disasscz
		.word disass

		.word dosysopencz
		.word dosysopen

		.word dosysclosecz
		.word dosysclose

		.word dosysreadcz
		.word dosysread

		.word dosyswritecz
		.word dosyswrite

		.word dosysreadbcz
		.word dosysreadblk

		.word dosyswritebcz
		.word dosyswriteblk

		.word dosysseekcz
		.word dosysseek

		.word dosysctrlcz
		.word dosyscontrol

		.word mntminixcz
		.word mntminix

		.word unmntminixcz
		.word unmntminix

		.word dogetinodecz
		.word dogetinode

		.word dominixopencz
		.word dominixopen

		.word dogetcharscz
		.word dogetchars

		.word dofindinodecz
		.word dofindinode

		.word doopenfilecz
		.word doopenfile

		.word dostatfilecz
		.word dostatfile

		.word 0x0000
