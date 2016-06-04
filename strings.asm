;;; STRINGS ;;;

; nibtoaschex - convert a low nibble in a to a character in x, advancing it

nibtoaschex:	anda #0x0f		; mask out the high nibble
		adda #0x30		; add '0'
		cmpa #0x39		; see if we are past '9'
		ble nibtoaschexout	; no? number then, so we're done
		adda #0x07		; yes? letter then, add 'A'-'9'
nibtoaschexout:	sta ,x+			; add it
		rts		

; bytetoaschex - convert a byte in a to two characters in x, advancing it
		
bytetoaschex:	pshs a			; save original input byte
		lsra			; move high nibble into low nibble
		lsra			; ..
		lsra			; ..
		lsra			; ..
		bsr nibtoaschex		; convert the low nibble
		puls a			; get the original input back
		bsr nibtoaschex		; convert the high nibble
		rts

; wordtoaschex - convert a word in d to four characters in x, advancing it

wordtoaschex:	pshs b			; save low byte
		bsr bytetoaschex	; output high byte
		puls a			; restore low byte
		bsr bytetoaschex	; and output low byte
		rts

; concatstr - add string y to string x, not copying the null

concatstr:	lda ,y+			; get the char in y
		beq concatstrout	; if its a null then finish
		sta ,x+			; otherwise add it to x
		bra concatstr		; go back for more
concatstrout:	rts

; concatstrn - add a chars of y to x, not ocpying the null

concatstrn:	ldb ,y+
		stb ,x+
		deca
		beq concatstrnout
		bra concatstrn
concatstrnout:	rts

; strcmp - compare the string at x with the string at y, on exit z is set
; if the strings are the same. saves a, x and y

strcmp:		pshs a,x,y
strcmploop:	lda ,x+			; load left string byte
		beq endcheck		; see if we have reached the end
		cmpa ,y+		; compare with right
		bne notamatch		; no match, then out
		bra strcmploop		; back for more
endcheck:	lda ,y+			; check the right end
		bne notamatch		; not a null? no match
		setzero			; a null, so we have a match, set zero
		bra strcmpout		; done
notamatch:	setnotzero		; not a match, so not zero
strcmpout:	puls a,x,y
		rts
