;;; SERIAL PORT ;;;

; serial port setup - this needs more comments

serialinit:	lda #0b10000011
		sta BASEPA+LCR16C654	; 8n1 and config baud
		lda #0x30
		sta BASEPA+DLL16C654
		lda #0x00
		sta BASEPA+DLM16C654	; 9600
		lda #0b00000011
		sta BASEPA+LCR16C654	; 8n1 and back to normal

		rts

; put the char in a, returning when its sent - corrupts b

serialputchar:	ldb BASEPA+LSR16C654	; get status
		andb #0b00100000	; transmit empty
		beq serialputchar	; wait for port to be idle
		sta BASEPA+THR16C654	; output the char
		rts

; serialgetchar - gets a char, putting it in a

serialgetchar:	lda BASEPA+LSR16C654	; get status
		anda #0b0000001		; input empty?
		beq serialgetchar	; go back and look again
		lda BASEPA+RHR16C654	; get the char into a
serialgetcharo:	rts

; serialgetwto - same as above but with a c. 2 sec timeout

serialgetwto:	pshs x
		ldx #0xffff		; will delay for roughly 2 sec
timeoutloop:	lda BASEPA+LSR16C654	; get status register
		anda #0b00000001	; looking for rx bit
		beq notready		; dec counter
		lda BASEPA+RHR16C654	; get the rx'd byte
		clrb			; no timeout occured
		bra serialgettwoo	; done, exit with byte in a
notready:	leax -1,x		; dex
		bne timeoutloop		; look again, if x not expired
		ldb #1			; timeout occured
serialgettwoo:	puls x
		rts

; output a null terminated string

serialputstr:	lda ,x+			; get the next char
		beq serialputstro	; null found, bomb out
		bsr serialputchar	; output the character
		bra serialputstr	; more chars
serialputstro:	rts
