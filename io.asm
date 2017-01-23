		.include 'ascii.inc'
		.include 'system.inc'
		.include 'hardware.inc'
		.include 'debug.inc'

		.area ROM

;;;;; IO

; puts the string in y to the default io device

putstrdefio::	pshs x
		ldx defaultio		; get default io device
		lbsr putstr		; lower level call
		puls x
		rts

; puts the string in y to the device at x

putstr::	pshs a
1$:		lda ,y+			; get the next char
		beq 2$			; null found, bomb out
		lbsr syswrite		; output the character
		bra 1$			; more chars
2$:		puls a
		rts

; gets a string, filling it into y from the default io device

getstrdefio::	pshs x
		ldx defaultio		; get default io device
		lbsr getstr		; lower level call
		puls x
		rts

; gets a string, filling it into y from the device at x

getstr::	clrb			; set the length to 0
getstrloop:	lbsr sysread		; get a char in a
		beq getstrwait		; need to wait
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
getstrwait:	lda DEVICE_SIGNAL,x	; get the signal mask to wait on
		lbsr wait		; and wait...
		debugreg ^'Get string wait returned: ',DEBUG_DRIVER,DEBUG_REG_A
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
		ldy #newlinemsg		; and also...
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
		ldy #newlinemsg		; and also...
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
		ldy #newlinemsg		; and also...
		lbsr putstr		; output a newline
		rts

; PRIVATE

putzero:	pshs a
		lda #'0
		lbsr syswrite
		puls a
		rts

putone:		pshs a
		lda #'1
		lbsr syswrite
		puls a
		rts
