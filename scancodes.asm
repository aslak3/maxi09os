; scancode translation

		.include 'system.inc'
		.include 'ascii.inc'
		.include 'scancodes.inc'

		.area RAM

leftshifton:	.rmb 1
rightshifton:	.rmb 1

		.area ROM

unshiftmap:

; row 0

		.byte ASC_ESC		; escape
		.byte ASC_NUL		; unwired
		.byte ASC_F1		; f1
		.byte ASC_F2		; f2
		.byte ASC_F3		; f3
		.byte ASC_F4		; f4
		.byte ASC_F5		; f5
		.byte ASC_NUL		; unwired

		.byte ASC_F6		; f6
		.byte ASC_NUL		; blank
		.byte ASC_F7		; f7
		.byte ASC_F8		; f8
		.byte ASC_F9		; f9
		.byte ASC_F10		; f10
		.byte ASC_HELP		; help
		.byte ASC_NUL		; unused

; row 1

		.ascii '~'
		.ascii '1'
		.ascii '2'
		.ascii '3'
		.ascii '4'
		.ascii '5'
		.ascii '6'
		.ascii '7'

		.ascii '8'
		.ascii '9'
		.ascii '0'
		.ascii '-'
		.ascii '='
		.ascii '\'
		.byte ASC_UP		; cursor up
		.byte ASC_NUL		; unused

; row 2

		.byte ASC_HT		; tab
		.ascii 'q'
		.ascii 'w'
		.ascii 'e'
		.ascii 'r'
		.ascii 't'
		.ascii 'y'
		.ascii 'u'

		.ascii 'i'
		.ascii 'o'
		.ascii 'p'
		.ascii '['
		.ascii ']'
		.byte ASC_CR		; replaced: return
		.byte ASC_LEFT		; cursor left
		.byte ASC_NUL		; unused

; row 3

		.byte ASC_NUL		; caps lock
		.ascii 'a'
		.ascii 's'
		.ascii 'd'
		.ascii 'f'
		.ascii 'g'
		.ascii 'h'
		.ascii 'j'

		.ascii 'k'
		.ascii 'l'
		.ascii ';'
		.ascii /'/
		.byte ASC_NUL		; blank
		.byte ASC_DEL		; delete
		.byte ASC_RIGHT		; cursor right
		.byte ASC_NUL		; unused

; row 4

		.byte ASC_NUL		; blank
		.ascii 'z'
		.ascii 'x'
		.ascii 'c'
		.ascii 'v'
		.ascii 'b'
		.ascii 'n'
		.ascii 'm'

		.ascii ','
		.ascii '.'
		.ascii '/'
		.byte ASC_NUL		; unwired
		.byte ASC_SP
		.byte ASC_BS		; backspace
		.byte ASC_DOWN		; cursor down
		.byte ASC_NUL		; unused

; row 5 (meta)

		.byte ASC_NUL		; right shift
		.byte ASC_NUL		; right alt
		.byte ASC_NUL		; right amiga
		.byte ASC_NUL		; ctrl
		.byte ASC_NUL		; left shift
		.byte ASC_NUL		; left alt
		.byte ASC_NUL		; left amiga

shiftmap:

; row 0

		.byte ASC_ESC		; escape
		.byte ASC_NUL		; unwired
		.byte ASC_F1		; f1
		.byte ASC_F2		; f2
		.byte ASC_F3		; f3
		.byte ASC_F4		; f4
		.byte ASC_F5		; f5
		.byte ASC_NUL		; unwired

		.byte ASC_F6		; f6
		.byte ASC_NUL		; blank
		.byte ASC_F7		; f7
		.byte ASC_F8		; f8
		.byte ASC_F9		; f9
		.byte ASC_F10		; f10
		.byte ASC_HELP		; help
		.byte ASC_NUL		; unused

; row 1

		.ascii '`'
		.ascii '!'
		.ascii '@'
		.ascii ' '
		.ascii '$'
		.ascii '%'
		.ascii '^'
		.ascii '&'

		.ascii '*'
		.ascii '('
		.ascii ')'
		.ascii '_'
		.ascii '+'
		.ascii '|'
		.byte ASC_UP		; cursor up
		.byte ASC_NUL		; unused

; row 2

		.byte ASC_HT		; tab
		.ascii 'Q'
		.ascii 'W'
		.ascii 'E'
		.ascii 'R'
		.ascii 'T'
		.ascii 'Y'
		.ascii 'U'

		.ascii 'I'
		.ascii 'O'
		.ascii 'P'
		.ascii '{'
		.ascii '}'
		.byte ASC_CR		; replaced: return
		.byte ASC_LEFT		; cursor up
		.byte ASC_NUL		; unused

; row 3

		.byte ASC_NUL		; caps lock
		.ascii 'A'
		.ascii 'S'
		.ascii 'D'
		.ascii 'F'
		.ascii 'G'
		.ascii 'H'
		.ascii 'J'

		.ascii 'K'
		.ascii 'L'
		.ascii ':'
		.ascii '"'
		.byte ASC_NUL		; blank
		.byte ASC_DEL		; delete
		.byte ASC_RIGHT		; cursor right
		.byte ASC_NUL		; unused

; row 4

		.byte ASC_NUL		; blank
		.ascii 'Z'
		.ascii 'X'
		.ascii 'C'
		.ascii 'V'
		.ascii 'B'
		.ascii 'N'
		.ascii 'M'

		.ascii '<'
		.ascii '>'
		.ascii '?'
		.byte ASC_NUL		; unwired
		.byte ASC_SP
		.byte ASC_BS		; backspace
		.byte ASC_DOWN		; cursor down
		.byte ASC_NUL		; unused

; row 5 (meta)

		.byte ASC_NUL		; right shift
		.byte ASC_NUL		; right alt
		.byte ASC_NUL		; right amiga
		.byte ASC_NUL		; ctrl
		.byte ASC_NUL		; left shift
		.byte ASC_NUL		; left alt
		.byte ASC_NUL		; left amiga

; translate scancode in a register, returning the ascii a - if no char is
; needed then a is zero

mapscancode::	pshs b,x
		ldb #1			; 1 for down
		bita #0x80		; key going up orr down?
		beq keydown		; down
		clrb			; 0 for up
keydown:	anda #0x7f		; mask out the up/down; its in b
		cmpa #KEY_L_SHIFT	; left shift
		beq asciilshift
		cmpa #KEY_R_SHIFT	; right shift
		beq asciirshift
		tstb			; key direction?
		bne printablekey	; down, so convert it
nonprintable:	clra
mapscancodeo:	puls b,x
		rts			; otherwise we are done

asciilshift:	stb leftshifton		; set left shift pressed flag
		bra nonprintable	; done
asciirshift:	stb rightshifton	; set right shift pressed flag
		bra nonprintable	; done

printablekey:	ldx #unshiftmap		; assume we are not shifting
		tst leftshifton		; check for left shift down
		bne 2$			; is it?
		tst rightshifton	; check for right shift down
		bne 2$			; is it?
1$:		lda a,x			; find ascii value
		bra mapscancodeo
2$:		ldx #shiftmap
		bra 1$
