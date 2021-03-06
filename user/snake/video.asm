; Video bits

		.include '../include/subtable.inc'

		.include '../../include/ascii.inc'
		.include '../../include/hardware.inc'
		.include '../../include/v99lowlevel.inc'

		.include 'snake.inc'

		.globl spectrumfont
		.globl snaketiles
		.globl badtiles
		.globl walltiles
		.globl colours

; global variables

stamp::		.rmb 1
peek::		.rmb 1

; Local variables

printattab:	.rmb 2*24
vcounter:	.rmb 1

videoinit::	jsr [forbid]

		; graphics mode 1 - 32x24, 8x8 tiles
		loadconstreg VMODE0REG, 0b00000000
		loadconstreg VMODE1REG, 0b01100000
		loadconstreg VMODE2REG, 0b00001000
		loadconstreg VMODE3REG, 0b00000010

		; 0x8000 - video
		loadconstreg VVIDBASEREG, 0x20		; name reg 2
		; 0x9000 - tiles
		loadconstreg VPATTBASEREG, 0x12		; generator
		; 0xa000 - colours of tiles
		loadconstreg VCOLBASELREG, 0x80
		loadconstreg VCOLBASEHREG, 0x02
		; hack
		loadconstreg VDISPLAYPOSREG, 0x08

		jsr [permit]

		clr vcounter,pcr

		leax printattab,pcr	; prepare lookup table of row->vram
		ldy #0x8000		; vram starts at 0x8000
		lda #24			; 24 rows on the screen
printattabn:	sty ,x++		; save the start of the row
		leay 32,y		; a row is 32 coloumns wide
		deca			; next row
		bne printattabn		; until we've got to the last one

		; load the tile data, starting with the spectrum font

		ldy #0x9000		; clear all characters
		ldu #8*256		; 256 chars
		jsr [vclear]

		leax spectrumfont,pcr
		ldy #0x9000+(8*0x20)
		ldu #8*96		; 96 characters of font data
		jsr [vwrite]

		leax snaketiles,pcr
		ldy #0x9000+(8*0x80)
		ldu #8*4		; 4 characters of font data
		jsr [vwrite]

		leax badtiles,pcr
		ldy #0x9000+(8*0x88)
		ldu #8*2		; 2 characters of font data
		jsr [vwrite]

		leax walltiles,pcr
		ldy #0x9000+(8*0x90)
		ldu #8*8		; 8 characters of font data
		jsr [vwrite]

		; and the colours (8 tiles per colour)
		leax colours,pcr
		ldy #0xa000
		ldu #0x20
		jsr [vwrite]

		rts

; clear whole screen

clearscreen::	ldy #0x8000		; start at the top left corner
		ldu #32*24		; 32 x 24 chars
		jsr [vclear]
		rts

; claear all but the outside border

clearplayarea::	ldy #0x8000		; start at the top left corner
		ldu #30			; we always clear 30 bytes
		leay 32+1,y		; skip the top row of border + 1 col
		lda #22			; 22 rows to clear
nextrow:	jsr [vclear]		; clear the 30 cols
		leay 32,y		; skip to the left most col on next row
		deca			; dec the row counter
		bne nextrow		; more rows?
		rts

; prints the string at x (until null) at row a, col b

printstrat::	leay printattab,pcr	; the row->vram addres table
		lsla			; double the row; table of addresses
		ldy a,y			; get the vram address
		leay b,y		; add the column count on
		jsr [forbid]
		jsr [vseekwrite]	; and set write mode
printstratn:	lda ,x+			; get the frist byte we are writing
		beq printstratout	; see if it's a null, then done
		writeaport0		; output it to the vdc
		bra printstratn		; back for more
printstratout:	jsr [permit]
		rts

; write the stamp byte to row a, col b and output the char. a and b are
; retained for conistency with peekat.

stampat::	pshs a,b		; save a and b
		leay printattab,pcr	; the row->vram addres table
		lsla			; double the row; table of addresses
		ldy a,y			; get the vram address
		leay b,y		; add the column count on
		lda stamp,pcr		; load what we are stamping
		jsr [forbid]
		jsr [vseekwrite]	; and set write mode
		writeaport0		; output it to the vdc
		jsr [permit]
		puls a,b		; restore a and b
		rts

; the reverse of stampat; the tile at a, b is saved into the stamp variable.
; a, b is retained so a following stampat call can replace the tile
; (assuming it is nothing bad)

peekat::	pshs a,b		; save a and b
		leay printattab,pcr	; the row->vram addres table
		lsla			; double the row; table of addresses
		ldy a,y			; get the vram address
		leay b,y		; add the column count on
		jsr [forbid]
		jsr [vseekread]		; set to read mode
		lda VPORT0		; read what's at the tile position
		jsr [permit]
		sta peek,pcr		; ave it into the peek variable
		puls a,b		; a and b have the row, col on exit
		rts

; draw a box. passed the coordinates on the u stack as follows, on entry:
;   u+3 : top left : column (b)
;   u+2 : top left : row (a)
;   u+1 : bottom right, column (b)
;   u+0 : bottom right, row (a)

drawbox::	lda #TOPLEFTTILE
		sta stamp,pcr
		lda 4,s
		ldb 5,s
		lbsr stampat

		lda #TOPTILE
		sta stamp,pcr
		lda 4,s
		ldb 5,s
		incb
topborder:	lbsr stampat
		incb
		cmpb 1,s
		bne topborder

		lda #TOPRIGHTTILE
		sta stamp,pcr
		lda 4,s
		ldb 3,s
		lbsr stampat

		lda #RIGHTTILE
		sta stamp,pcr
		lda 4,s
		ldb 3,s
		inca
rightborder:	lbsr stampat
		inca
		cmpa 2,s
		bne rightborder

		lda #BOTTOMRIGHTTILE
		sta stamp,pcr
		lda 2,s
		ldb 3,s
		lbsr stampat

		lda #BOTTOMTILE
		sta stamp,pcr
		lda 2,s
		ldb 5,s
		incb
bottomborder:	lbsr stampat
		incb
		cmpb 3,s
		bne bottomborder

		lda #BOTTOMLEFTTILE
		sta stamp,pcr
		lda 2,s
		ldb 5,s
		lbsr stampat

		lda #LEFTTILE
		sta stamp,pcr
		lda 4,s
		ldb 5,s
		inca
leftborder:	lbsr stampat
		inca
		cmpa 2,s
		bne leftborder

		rts
