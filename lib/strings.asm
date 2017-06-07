		.include 'include/system.inc'
		.include 'include/ascii.inc'

		.area ROM

; nibtoaschex - convert a low nibble in a to a character in x, advancing it

nibtoaschex::	anda #0x0f		; mask out the high nibble
		adda #0x30		; add '0'
		cmpa #0x39		; see if we are past '9'
		ble 1$			; no? number then, so we're done
		adda #0x07		; yes? letter then, add 'A'-'9'
1$:		sta ,x+			; add it
		rts		

; bytetoaschex - convert a byte in a to two characters in x, advancing it
		
bytetoaschex::	pshs a			; save original input byte
		lsra			; move high nibble into low nibble
		lsra			; ..
		lsra			; ..
		lsra			; ..
		bsr nibtoaschex		; convert the low nibble
		puls a			; get the original input back
		bsr nibtoaschex		; convert the high nibble
		rts

; wordtoaschex - convert a word in d to four characters in x, advancing it

wordtoaschex::	pshs b			; save low byte
		bsr bytetoaschex	; output high byte
		puls a			; restore low byte
		bsr bytetoaschex	; and output low byte
		rts

; copytstr - add string y to string x, setting a null at end. on exit, x
; points to the null

copystr::	pshs a
1$:		lda ,y+			; get the char in y
		beq 2$			; if its a null then finish
		sta ,x+			; otherwise add it to x
		bra 1$			; go back for more
2$:		clr ,x			; set a null, but don't advance x
		puls a
		rts

; strcmp - compare the string at x with the string at y, on exit z is set
; if the strings are the same. saves a, x and y

strcmp::	pshs a,x,y
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

; parse a stream of asci hex and strings in x into y

parseinput::	pshs a,y
commandinput:	lda ,x+			; get the char from command name
		beq noparams		; null? out we go
		cmpa #ASC_SP		; space?
		bne notspace		; no? then skip null insertion
		clr ,y+			; set char to null
		bra nextparseinput	; now the params...
notspace:	sta ,y+			; save it
		bra commandinput	; back for from the command
noparams:	clr ,y+			; mark end of command
		bra parseinputout		; end, no params
nextparseinput:	lbsr skipspaces
		lda ,x			; get the char under the new pos
		beq parseinputout
		cmpa #'"		; double quote
		beq parsestring		; if so it is a string
		cmpa #'-		; hyphen
		beq parseoption		; if so then parse it as an option
		lda 2,x			; get the next but one char
		beq parsebyte		; null? it's a byte
		cmpa #ASC_SP		; space
		beq parsebyte		; yes? it's a byte
		lda 4,x			; get the next but 3 char
		beq parseword		; null? it's a word
		cmpa #ASC_SP		; space
		beq parseword		; yes? it's a word
		bra parseinputout	; no match, so end
parsebyte:	lda #1			; code 1 for bytes
		sta ,y+			; add it into the stream
		lbsr aschextobyte	; yes? this pair must be a byte
		sta ,y+			; save it in y
		bra nextparseinput	; look for more
parseword:	lda #2			; code 2 for words
		sta ,y+			; add it in to the stream
		lbsr aschextoword	; if we get here it must be a word
		std ,y++		; save the word in y
		bra nextparseinput	; back for more tokens
parsestring:	lda #3			; type 3 for strings
		sta ,y+			; save the type
		leax 1,x		; move to after the quote
stringloop:	lda ,x+			; get the string data
		beq parsestringout	; end of the string (bad though)
		cmpa #'"		; closing quote
		beq parsestringout	; yes? end of the string
		sta ,y+			; add it in
		bne stringloop		; check for nulls too
parsestringout:	clr ,y+			; finish the string
		bra nextparseinput	; back for more elements
parseoption:	lda #4			; type 4 for options
		sta ,y+			; save the type
		leax 1,x		; move to after the hyphen
		lda ,x+			; get the option character
		sta ,y+			; save the option character
		bra nextparseinput	; back for more tokens
parseinputout:	clr ,y+			; null ender
		puls a,y
		rts

; printableasc - converts non printables to . in a

printableasc::	cmpa #0x20		; compare with space
		blo 1$			; lower? it must be a unprintable
		cmpa #0x7e		; compare with the end char
		bhi 1$			; higher? it must be unprintable
		rts			; if not, leave it alone
1$:		lda #0x2e		; otherwise flatten it to a dot
		rts

; topupper - converts the char in a to uppercase

toupper::	cmpa #'a		; compare with "a"
		blo 1$			; lower? not a letter
		cmpa #'z		; compare with "z"
		bhi 1$			; higher? not a letter
		suba #'a-'A		; convert to uppercase
1$:		rts

; match a string in y to the string,userdata array, returning the userdata
; following the string in the array.  this is usually a subroutine address
; and it goes in x. the array goes in u. also, y is advanced to the end
; of the string, which is where parseargs will (presumably) have put the
; arguments. On no match, y is left alone

strmatcharray::	ldx ,u++		; get the string
		beq strmatchfailed	; end of string?
		lbsr strcmp		; compare the command with the list
		bne 2$			; no match? check next one
1$:		tst ,y+			; the caller is interested in args
		bne 1$			; advance y to the arguments
		ldx ,u			; get user data
		setzero			; success
		bra strmatcharrayo	; out
2$:		ldx ,u++		; need to advance past sub pointer
		bra strmatcharray	; before checking next command
strmatchfailed:	setnotzero		; failure
strmatcharrayo:	rts

;;; PRIVATE

; jump x across spaces

skipspaces:	lda ,x+			; skip a space
		cmpa #0x20		; is it a space?
		beq skipspaces		; yes? then go back and look for more
		leax -1,x		; back 1
		rts

; aschextonib - convert a char on x to a low nibble in a

aschextonib:	lda ,x+			; get the charater
		suba #0x30		; subtract '0'
		cmpa #0x10		; less then 9?
		blo aschextonibout	; yes? we are done
		suba #0x07		; no? subtract 'A'-'9'
		cmpa #0x10		; less then 16?
		blo aschextonibout	; was uppercase
		suba #0x20
aschextonibout:	rts

; aschextobyte - convert two characters on x to a byte in a

aschextobyte:	leas -1,s		; make room on stack for 1 temp byte
		bsr aschextonib		; convert the low nibble
		lsla			; make it the high nibble
		lsla			; ..
		lsla			; ..
		lsla			; ..
		sta ,s			; save it on the stack
		bsr aschextonib		; convert the real low nibble
		ora ,s			; combine it with the high nibble
		leas 1,s		; shrink the stack again
		rts

; aschextowrd - convert four characters on x to a word in d

aschextoword:	bsr aschextobyte	; convert the first byte in the string
		tfr a,b			; move it asside
		bsr aschextobyte	; convert the second byte
		exg a,b			; swap the bytes
		rts			; d is now the word
