		.include 'ascii.inc'
		.include 'system.inc'
		.include 'debug.inc'

		.area ROM

;;;;; IO

; puts the string in y to the device at x

putstr::	lda ,y+			; get the next char
		beq 1$			; null found, bomb out
		lbsr syswrite		; output the character
		bra putstr		; more chars
1$:		rts

outofwaitmsg:	.asciz 'out of wait\r\n'

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
		debug #outofwaitmsg	; done waiting, we have some data
		debuga
		bra getstrloop		; go and get the new data
