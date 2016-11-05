		.include 'system.inc'
		.include 'externs.inc'

		.area RAM

inputbuffer:	.rmb 80
parambuffer:	.rmb 100
iodevice:	.rmb 2
dumppointer:	.rmb 2
dumpcounter:	.rmb 2

		.area ROM

promptmsg:	.asciz '> '
consolename:	.asciz 'console'
commfailedmsg:	.asciz 'Command failed\r\n'
nosuchmsg:	.asciz 'No such command\r\n'

; monitor entry point

monitorstart::	ldx #consolename
		lda #4
		clrb
		lbsr sysopen
		stx iodevice

mainloop:	ldx iodevice
		ldy #promptmsg		; '>' etc
		lbsr putstr		; output that
		
		ldy #inputbuffer	; now we need a command
		lbsr getstr		; get the command (waiting as needed)

		ldy #newlinemsg
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
commanderror:	ldx iodevice
		ldy #commfailedmsg
		lbsr putstr		; show error
		bra mainloop

commandarraye:	ldx iodevice
		ldy #nosuchmsg
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

		ldx iodevice		; io device for the monitor

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

		ldy #newlinemsg		; newline
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

; shows the registers as they were when the monitor was entered

ccmsg:		.asciz 'CC: '
amsg:		.asciz '  A: '
bmsg:		.asciz '  B: '
dpmsg:		.asciz '  DP: '
xmsg:		.asciz '  X: '
ymsg:		.asciz '  Y: '
umsg:		.asciz '  U: '
pcmsg:		.asciz '  PC: '

showregisters:	ldx iodevice
		ldy #ccmsg		; get the 'C: '
		lbsr putstr
		lda 0,u			; get the register value
		lbsr putbyte

		ldy #amsg		; same again
		lbsr putstr
		lda 1,u			; ...
		lbsr putbyte		; ...

		ldy #bmsg
		lbsr putstr
		lda 2,u
		lbsr putbyte

		ldy #dpmsg
		lbsr putstr
		lda 3,u
		lbsr putbyte

		ldy #xmsg
		lbsr putstr
		ldd 4,u
		lbsr putword

		ldy #ymsg
		lbsr putstr
		ldd 6,u
		lbsr putword

		ldy #umsg
		lbsr putstr
		ldd 8,u
		lbsr putword

		ldy #pcmsg
		lbsr putstr
		ldd 10,u
		lbsr putword

		ldy #newlinemsg
		lbsr putstr
		clra			; we always succeed
		rts


; z BB WWWW 'STRING' .... - test the parser by outputting what was parsed

bytefoundmsg:	.asciz 'byte: '
wordfoundmsg:	.asciz 'word: '
stringfoundmsg:	.asciz 'string: '

parsetest:	lbsr doparse
		tfr y,u
		ldx iodevice

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

bytefound:	ldy #bytefoundmsg
		lbsr putstr
		lda ,u+
		lbsr putbyte
		ldy #newlinemsg
		lbsr putstr
		bra parsetestloop

wordfound:	ldy #wordfoundmsg
		lbsr putstr
		ldd ,u++
		lbsr putword
		ldy #newlinemsg
		lbsr putstr
		bra parsetestloop

stringfound:	ldy #stringfoundmsg
		lbsr putstr
		tfr u,y
		lbsr putstr
		tfr y,u
		ldy #newlinemsg
		lbsr putstr
		bra parsetestloop		

readbyte:	lbsr doparse
		lda ,y+
		cmpa #2			; is it a word?
		lbne generalerror	; validation error

		ldy ,y

		ldx iodevice
		lda ,y
		lbsr putbyte
		ldy #newlinemsg
		lbsr putstr
		clra
		rts

; shows some help text

helpmsg:	.ascii 'Commands:\r\n'
		.ascii '  r : show registers\r\n'
		.ascii '  w AAAA BB WWWW "STRING" ... : write to AAAA bytes, words, strings\r\n'
		.ascii '  d AAAA LLLL : dump from AAAA count LLLL bytes in hex\r\n'
		.ascii '  R MMMM : read the byte at MMMM and display it\r\n'
		.ascii '  h or ? : this help\r\n'
		.asciz '\r\n'

showhelp:	ldx iodevice
		ldy #helpmsg		; and the help text
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
		.word 0x0000
		.byte 0x00
