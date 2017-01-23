		.include 'system.inc'
		.include 'externs.inc'

		.area RAM

inputbuffer:	.rmb 80
parambuffer:	.rmb 100
dumppointer:	.rmb 2
dumpcounter:	.rmb 2

		.area ROM

monstartz:	.asciz '\r\nMonitor, press enter to pause switching\r\n\r\n'
promptz:	.asciz '> '
consolename:	.asciz 'console'
commfailedz:	.asciz 'Command failed\r\n'
nosuchz:	.asciz 'No such command\r\n'

; monitor entry point

monitorstart::	ldx defaultio
		ldy #monstartz
		lbsr putstr

		ldy #inputbuffer
		lbsr getstr

		lbsr forbid

mainloop:	ldx defaultio
		ldy #promptz		; '>' etc
		lbsr putstr		; output that
		
		ldy #inputbuffer	; now we need a command
		lbsr getstr		; get the command (waiting as needed)

		ldy #newlinez
		lbsr putstr

		lda inputbuffer		; get the first char
		ldx #commandarray	; setup the command pointer
nextcommand:	ldy ,x++		; get the sub address
		ldb ,x			; get the command letter
		beq commandarraye	; end of command list?
		cmpa ,x+		; compare input letter with array item
		bne nextcommand		; no match? check next one
		jsr ,y			; jump to subroutine
		bne commanderror	; error check for zero
		bra mainloop		; back to top
commanderror:	ldx defaultio
		ldy #commfailedz
		lbsr putstr		; show error
		bra mainloop

commandarraye:	ldx defaultio
		ldy #nosuchz
		lbsr putstr		; show error message
		bra mainloop

; general error handler branch for commands that fail

generalerror:	lda #1
		rts

;;; COMMANDS ;;;

; dumpmemory - 'd AAAA BBBB' - dumps from AAAA, BBBB bytes
;
; C000  48 65 6C 6C 6F 2C 20 74  68 69 73 20 69 73 20 61  [Hello, this is a]

dumpmemory:	lbsr doparse		; parse hexes, filling out inputbuffer
		lda ,y+			; get the type
		cmpa #2			; is it a word?
		lbne generalerror	; validation error
		ldd ,y++		; start address
		andb #0xf0		; round to nearest 16
		std dumppointer		; store it in the variable
		lda ,y+			; get the type
		cmpa #2			; is it a word?
		bne generalerror	; yes, mark it as bad
		ldd ,y++		; length/count of bytes
		andb #0xf0		; also rounded
		std dumpcounter		; store it in the variable

		ldx defaultio		; io device for the monitor

dumpnextrow:	ldd dumppointer		; get address of this row
		lbsr putword		; print the address into the buffer
		lda #0x20		; space
		lbsr syswrite
		lbsr syswrite

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

		ldy #newlinez		; newline
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

writememory:	lbsr doparse		; parse hexes, filling out inputbuffer
		lda ,y+			; get the type
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

; z BB WWWW 'STRING' .... - test the parser by outputting what was parsed

bytefoundz:	.asciz 'byte: '
wordfoundz:	.asciz 'word: '
stringfoundz:	.asciz 'string: '

parsetest:	lbsr doparse
		tfr y,u
		ldx defaultio

parsetestloop:	lda ,u+
		cmpa #1
		beq bytefound
		cmpa #2
		beq wordfound
		cmpa #3
		beq stringfound
		tsta
		beq parsetestout
		lbra generalerror

parsetestout:	clra
		rts

bytefound:	ldy #bytefoundz
		lbsr putstr
		lda ,u+
		lbsr putbyte
		ldy #newlinez
		lbsr putstr
		bra parsetestloop

wordfound:	ldy #wordfoundz
		lbsr putstr
		ldd ,u++
		lbsr putword
		ldy #newlinez
		lbsr putstr
		bra parsetestloop

stringfound:	ldy #stringfoundz
		lbsr putstr
		tfr u,y
		lbsr putstr
		tfr y,u
		ldy #newlinez
		lbsr putstr
		bra parsetestloop		

readbyte:	lbsr doparse
		lda ,y+
		cmpa #2			; is it a word?
		lbne generalerror	; validation error

		ldy ,y

		ldx defaultio
		lda ,y
		lbsr putbyte
		ldy #newlinez
		lbsr putstr
		clra
		rts

totalmemz:	.asciz 'Total: '
freememz:	.asciz 'Free: '
largestmemz:	.asciz 'Largest: '

showmemory:	ldx defaultio

		lda #MEM_TOTAL
		lbsr memoryavail
		ldy #totalmemz
		lbsr putlabw

		lda #MEM_FREE
		lbsr memoryavail
		ldy #freememz
		lbsr putlabw

		lda #MEM_LARGEST
		lbsr memoryavail
		ldy #largestmemz
		lbsr putlabw

		clra
		rts

readytasksz:	.asciz 'READY TASKS\r\n'
waitingtasksz:	.asciz 'WAITING TASKS\r\n'

showtasks:	ldy #readytasksz
		lbsr putstrdefio
		ldy #readytasks
		lbsr showtasklist
		ldy #newlinez
		lbsr putstrdefio

		ldy #waitingtasksz
		lbsr putstrdefio
		ldy #waitingtasks
		lbsr showtasklist
		ldy #newlinez
		lbsr putstrdefio

		clra
		rts

showtasklist:	ldx LIST_HEAD,y		; get the first node
showtaskloop:	ldy NODE_NEXT,x		; get its following node
                beq endtasklist
		lbsr showtask		; show info about task x
		ldx NODE_NEXT,x
		bra showtaskloop
endtasklist:	rts

lchevronsz:	.asciz '<<<'
rchevronsz:	.asciz '>>>'
taskz:		.asciz 'Task: '
parentz:	.asciz 'Parent: '
defaultioz:	.asciz 'Default IO: '
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

		ldy #newlinez
		lbsr putstr
		tfr u,d
		ldy #taskz
		lbsr putlabw

		ldd TASK_PARENT,u
		ldy #parentz
		lbsr putlabw

		ldd TASK_DISPCOUNT,u
		ldy #dispatchcountz
		lbsr putlabw

		ldd TASK_DEF_IO,u
		ldy #defaultioz
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

		puls x
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

		ldy #newlinez
		lbsr putstr

		puls a,u

		rts


quit:		lbsr permit
		lbra monitorstart

; shows some help text

helpz:		.ascii 'Commands:\r\n'
		.ascii '  r : show registers\r\n'
		.ascii '  w AAAA BB WWWW "STRING" ... : write to AAAA bytes, words, strings\r\n'
		.ascii '  d AAAA LLLL : dump from AAAA count LLLL bytes in hex\r\n'
		.ascii '  R MMMM : read the byte at MMMM and display it\r\n'
		.ascii '  q : quit monitor and resume task switching\r\n'
		.ascii '  h or ? : this help\r\n'
		.asciz '\r\n'

showhelp:	ldx defaultio
		ldy #helpz		; and the help text
		lbsr putstr
		clra			; we always suceed
		rts


doparse:	ldx #inputbuffer+1
		ldy #parambuffer
		lbsr parseinput
		rts

commandarray:	.word dumpmemory
		.ascii 'd'
		.word writememory
		.ascii 'w'
		.word showhelp
		.ascii '?'			; same command different letter
		.word parsetest
		.ascii 'z'
		.word readbyte
		.ascii 'R'
		.word showmemory
		.ascii 'm'
		.word showtasks
		.ascii 't'
		.word quit
		.ascii 'q'
		.word 0x0000
		.byte 0x00
