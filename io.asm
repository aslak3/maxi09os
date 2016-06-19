;;;;; IO

; puts the string in y to the device at x

putstr:		lda ,y+			; get the next char
		beq 1$			; null found, bomb out
		lbsr syswrite		; output the character
		bra putstr		; more chars
1$:		rts

outofwaitmsg:	.asciz 'outof wait\r\n'

; gets a string, filling it into y from the device at x

getstr:		clrb			; set the length to 0
getstrloop:	lbsr sysread		; get a char in a
		beq getstrwait		; need to wait
		cmpa #CR		; cr?
		beq getstrout		; if it is, then out
		cmpa #LF		; lf?
		beq getstrout		; if it is, then out
		cmpa #BS		; backspace pressed?
		beq getstrbs		; handle backspace
		cmpa #SP		; check if less then space
		blo getstrloop		; if so, then ignore it
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
		lda #BS			; move cursor back one
		lbsr syswrite
		lda #SP			; then erase and move forward
		lbsr syswrite
		lda #BS			; then back one again
		lbsr syswrite
		bra getstrloop		; echo the bs and charry on
getstrwait:	lda DEVICE_SIGNAL,x
		lbsr wait
		debug #outofwaitmsg
		debuga
		bra getstrloop
