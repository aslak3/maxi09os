		.include 'include/ascii.inc'
		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl sysread
		.globl syswrite
		.globl defaultio
		.globl wait
		.globl newlinez

		.area ROM

;;;;; IO

; general purpose io "error" handler - call after an io function has
; returned non zero. it will then wait or handle the break signal.

breakz:		.asciz 'BREAK!!!\r\n'

handleioerror:: pshs a,y
		cmpa #IO_ERR_WAIT	; should we wait?
		beq dowait		; go and wait before returning
		cmpa #IO_ERR_BREAK	; got a break?
		beq dobreak		; handle the break
		bra handleioerroro
dowait:		debug ^'Handle IO error, waiting',DEBUG_LIB
		lda DEVICE_SIGNAL,x	; get the signal mask to wait on
		lbsr wait		; and wait...
		bra handleioerroro	; now return, caller should retry	
dobreak:	debug ^'Handle IO error, break',DEBUG_LIB
		ldy #breakz		; break!
		lbsr putstr
		swi2
handleioerroro:	puls a,y
		rts

; get a char on the default io channel, waiting if needed

getchardefio::	pshs x
		ldx defaultio		; get the default io device
		bsr getchar		; get the char, waiting if needed
		puls x
		rts

; get a char from device x, waiting if needed

getchar::	lbsr sysread		; get the byte into a
		bne getcharerror	; error? deal with it
		rts
getcharerror:	lbsr handleioerror	; deal with error
		bra getchar

; put a char to device x, waiting if needed

putchardefio::	pshs x
		ldx defaultio		; get the default io device
		bsr putchar		; put the charater in a, might wait
		puls x
		rts

; put a char to device x, waiting if needed

putchar::	lbsr syswrite		; get the byte into a
		bne getcharerror	; error? deal with it
		rts
putcharerror:	lbsr handleioerror	; deal with error
		rts

; gets a buffer from device at x, memory in y, length in u

getchars::	pshs a,y,u
		exg u,y			; u has no zero bit on leau
getcharsloop:	lbsr sysread		; get byte in a
		bne getcharserror	; need to deal with errors
		sta ,u+			; save in callers memory
		leay -1,y		; dec byte counter
		bne getcharsloop	; back for more
		puls a,y,u
		rts
getcharserror:	lbsr handleioerror	; deal with error
		bra getcharsloop

; puts the string in y to the default io device

putstrdefio::	pshs x
		ldx defaultio		; get default io device
		lbsr putstr		; lower level call
		puls x
		rts

; puts the string in y to the device at x

putstr::	pshs a,y
1$:		lda ,y+			; get the next char
		beq 2$			; null found, bomb out
		lbsr syswrite		; output the character
		bra 1$			; more chars
2$:		puls a,y
		rts

; gets a string, filling it into y from the default io device

getstrdefio::	pshs x
		ldx defaultio		; get default io device
		lbsr getstr		; lower level call
		puls x
		rts

; gets a string, filling it into y from the device at x

getstr::	pshs a,b,y
		clrb			; set the length to 0
getstrloop:	lbsr sysread		; get a char in a
		bne getstrerror		; need to wait
		cmpa #ASC_CR		; cr?
		beq getstrout		; if it is, then out
		cmpa #ASC_LF		; lf?
		beq getstrout		; if it is, then out
		cmpa #ASC_BS		; backspace pressed?
		beq getstrbs		; handle backspace
		sta ,y+			; add it to string
		incb			; increment the number of chars
getstrecho:	lbsr syswrite		; echo it
		bra getstrloop		; get more
getstrout:	clr ,y+			; add a null
		ldy #newlinez		; tidy up ...
		lbsr putstr		; ... with a newline
		puls a,b,y
		rts
getstrbs:	tstb			; see if the char count is 0
		beq getstrloop		; do nothing if already zero
		decb			; reduce count by 1
		clr ,y			; null the current char
		leay -1,y		; move the pointer back 1
		lda #ASC_BS		; move cursor back one
		lbsr syswrite
		lda #ASC_SP		; then erase and move forward
		lbsr syswrite
		lda #ASC_BS		; then back one again
		lbsr syswrite
		bra getstrloop		; echo the bs and charry on
getstrerror:	lbsr handleioerror	; deal with error, might wait
		debugreg ^'Get string wait returned: ',DEBUG_LIB,DEBUG_REG_A
		bra getstrloop		; go and get the new data

; putnib - convert a low nibble in a and output it via x

putnib:		anda #0x0f		; mask out the high nibble
		adda #0x30		; add '0'
		cmpa #0x39		; see if we are past '9'
		ble 1$			; no? number then, so we're done
		adda #0x07		; yes? letter then, add 'A'-'9'
1$:		lbsr syswrite		; output it
		rts		

; putbyte - convert a byte in a to two characters and send them via def io

putbytedefio::	pshs x
		ldx defaultio		; get the default io device
		bsr putbyte		; lowerlevel call
		puls x
		rts

; putbyte - convert a byte in a to two characters and send them via x
	
putbyte::	pshs a			; save original input byte
		lsra			; move high nibble into low nibble
		lsra			; ..
		lsra			; ..
		lsra			; ..
		bsr putnib		; convert the low nibble
		puls a			; get the original input back
		bsr putnib		; convert the high nibble
		rts

; putbytebdefio - output the byte in a in binary form to the default device

putbytebdefio::	pshs x
		ldx defaultio		; get default io device
		lbsr putbyteb		; lower level call
		puls x
		rts

; putbyteb - output the byte in a in binary form to the device in x

putbyteb::	pshs a,b
		ldb #8			; 8 bits in a byte	
1$:		lsla			; shift highest bit into cary
		bcs 2$			; test bit shifted in carry
		lbsr putzero		; output a zero
		bra 3$			; skip forward
2$:		lbsr putone		; output a one
3$:		decb			; reduce the bit counter
		bne 1$			; back for more bits
		puls a,b
		rts

; putworddefio - convert a word in d to four characters and send them via
; default io

putworddefio::	pshs x
		ldx defaultio		; get default io device
		bsr putword		; lower level call
		puls x
		rts

; putword - convert a word in d to four characters and send them via x

putword::	pshs b			; save low byte
		bsr putbyte		; output high byte
		puls a			; restore low byte
		bsr putbyte		; and output low byte
		rts

; putlabwdefio - output the string in y, then the word in d, followed by
; a newline to the default device

putlabwdefio::	pshs x
		ldx defaultio		; get default io device
		lbsr putlabw		; lower level call
		puls x
		rts

; putlabw - output the string in y, then the word in d, followed by a
; newline to the device in x

putlabw::	lbsr putstr		; output the label
		lbsr putword		; output the word
		ldy #newlinez		; and also...
		lbsr putstr		; output a newline
		rts

; putlabbdefio - output the string in y, then the byte in a, followed by
; a newline to the default device

putlabbdefio::	pshs x
		ldx defaultio		; get default io device
		lbsr putlabb		; lower level call
		puls x
		rts

; putlabb - output the string in y, then the byte in a, followed by a
; newline to the device in x

putlabb::	lbsr putstr		; output the label
		lbsr putbyte		; output the word
		ldy #newlinez		; and also...
		lbsr putstr		; output a newline
		rts

; putlabbbdefio - output the string in y, then the byte in a in binary,
; followed by a newline to the default device

putlabbbdefio::	pshs x
		ldx defaultio		; get default io device
		lbsr putlabbb		; lower level call
		puls x
		rts

; putlabbb - output the string in y, then the byte in a in binary, followed
; by a newline to the device in x

putlabbb::	lbsr putstr		; output the label
		lbsr putbyteb		; output the byte in binary
		ldy #newlinez		; and also...
		lbsr putstr		; output a newline
		rts

; PRIVATE

putzero:	pshs a
		lda #'0			; ascii 0
		lbsr syswrite		; write it to x
		puls a
		rts

putone:		pshs a
		lda #'1			; ascii 1
		lbsr syswrite		; write it to x
		puls a
		rts
