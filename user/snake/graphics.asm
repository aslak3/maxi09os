; Converted from source material at: http://www.wearmouth.demon.co.uk/

; -------------------------------
; THE 'ZX SPECTRUM CHARACTER SET'
; -------------------------------

;; char-set

; $20 - Character: ' ' CHR$(32)

spectrumfont::	.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000

; $21 - Character: '!'		CHR$(33)

		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00000000

; $22 - Character: '"'		CHR$(34)

		.byte 0b00000000
		.byte 0b00100100
		.byte 0b00100100
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000

; $23 - Character: '#'		CHR$(35)

		.byte 0b00000000
		.byte 0b00100100
		.byte 0b01111110
		.byte 0b00100100
		.byte 0b00100100
		.byte 0b01111110
		.byte 0b00100100
		.byte 0b00000000

; $24 - Character: '$'		CHR$(36)

		.byte 0b00000000
		.byte 0b00001000
		.byte 0b00111110
		.byte 0b00101000
		.byte 0b00111110
		.byte 0b00001010
		.byte 0b00111110
		.byte 0b00001000

; $25 - Character: '0b'		CHR$(37)

		.byte 0b00000000
		.byte 0b01100010
		.byte 0b01100100
		.byte 0b00001000
		.byte 0b00010000
		.byte 0b00100110
		.byte 0b01000110
		.byte 0b00000000

; $26 - Character: '&'		CHR$(38)

		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00101000
		.byte 0b00010000
		.byte 0b00101010
		.byte 0b01000100
		.byte 0b00111010
		.byte 0b00000000

; $27 - Character: '''		CHR$(39)

		.byte 0b00000000
		.byte 0b00001000
		.byte 0b00010000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000

; $28 - Character: '('		CHR$(40)

		.byte 0b00000000
		.byte 0b00000100
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00000100
		.byte 0b00000000

; $29 - Character: ')'		CHR$(41)

		.byte 0b00000000
		.byte 0b00100000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00100000
		.byte 0b00000000

; $2A - Character: '*'		CHR$(42)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00010100
		.byte 0b00001000
		.byte 0b00111110
		.byte 0b00001000
		.byte 0b00010100
		.byte 0b00000000

; $2B - Character: '+'		CHR$(43)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00111110
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00000000

; $2C - Character: ','		CHR$(44)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00010000

; $2D - Character: '-'		CHR$(45)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00111110
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000

; $2E - Character: '.'		CHR$(46)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00011000
		.byte 0b00011000
		.byte 0b00000000

; $2F - Character: '/'		CHR$(47)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000010
		.byte 0b00000100
		.byte 0b00001000
		.byte 0b00010000
		.byte 0b00100000
		.byte 0b00000000

; $30 - Character: '0'		CHR$(48)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000110
		.byte 0b01001010
		.byte 0b01010010
		.byte 0b01100010
		.byte 0b00111100
		.byte 0b00000000

; $31 - Character: '1'		CHR$(49)

		.byte 0b00000000
		.byte 0b00011000
		.byte 0b00101000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00111110
		.byte 0b00000000

; $32 - Character: '2'		CHR$(50)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000010
		.byte 0b00000010
		.byte 0b00111100
		.byte 0b01000000
		.byte 0b01111110
		.byte 0b00000000

; $33 - Character: '3'		CHR$(51)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000010
		.byte 0b00001100
		.byte 0b00000010
		.byte 0b01000010
		.byte 0b00111100
		.byte 0b00000000

; $34 - Character: '4'		CHR$(52)

		.byte 0b00000000
		.byte 0b00001000
		.byte 0b00011000
		.byte 0b00101000
		.byte 0b01001000
		.byte 0b01111110
		.byte 0b00001000
		.byte 0b00000000

; $35 - Character: '5'		CHR$(53)

		.byte 0b00000000
		.byte 0b01111110
		.byte 0b01000000
		.byte 0b01111100
		.byte 0b00000010
		.byte 0b01000010
		.byte 0b00111100
		.byte 0b00000000

; $36 - Character: '6'		CHR$(54)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000000
		.byte 0b01111100
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b00111100
		.byte 0b00000000

; $37 - Character: '7'		CHR$(55)

		.byte 0b00000000
		.byte 0b01111110
		.byte 0b00000010
		.byte 0b00000100
		.byte 0b00001000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00000000

; $38 - Character: '8'		CHR$(56)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000010
		.byte 0b00111100
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b00111100
		.byte 0b00000000

; $39 - Character: '9'		CHR$(57)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b00111110
		.byte 0b00000010
		.byte 0b00111100
		.byte 0b00000000

; $3A - Character: ':'		CHR$(58)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00000000

; $3B - Character: ';'		CHR$(59)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00100000

; $3C - Character: '<'		CHR$(60)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000100
		.byte 0b00001000
		.byte 0b00010000
		.byte 0b00001000
		.byte 0b00000100
		.byte 0b00000000

; $3D - Character: '='		CHR$(61)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00111110
		.byte 0b00000000
		.byte 0b00111110
		.byte 0b00000000
		.byte 0b00000000

; $3E - Character: '>'		CHR$(62)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00001000
		.byte 0b00000100
		.byte 0b00001000
		.byte 0b00010000
		.byte 0b00000000

; $3F - Character: '?'		CHR$(63)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000010
		.byte 0b00000100
		.byte 0b00001000
		.byte 0b00000000
		.byte 0b00001000
		.byte 0b00000000

; $40 - Character: '@'		CHR$(64)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01001010
		.byte 0b01010110
		.byte 0b01011110
		.byte 0b01000000
		.byte 0b00111100
		.byte 0b00000000

; $41 - Character: 'A'		CHR$(65)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01111110
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b00000000

; $42 - Character: 'B'		CHR$(66)

		.byte 0b00000000
		.byte 0b01111100
		.byte 0b01000010
		.byte 0b01111100
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01111100
		.byte 0b00000000

; $43 - Character: 'C'		CHR$(67)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000010
		.byte 0b01000000
		.byte 0b01000000
		.byte 0b01000010
		.byte 0b00111100
		.byte 0b00000000

; $44 - Character: 'D'		CHR$(68)

		.byte 0b00000000
		.byte 0b01111000
		.byte 0b01000100
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000100
		.byte 0b01111000
		.byte 0b00000000

; $45 - Character: 'E'		CHR$(69)

		.byte 0b00000000
		.byte 0b01111110
		.byte 0b01000000
		.byte 0b01111100
		.byte 0b01000000
		.byte 0b01000000
		.byte 0b01111110
		.byte 0b00000000

; $46 - Character: 'F'		CHR$(70)

		.byte 0b00000000
		.byte 0b01111110
		.byte 0b01000000
		.byte 0b01111100
		.byte 0b01000000
		.byte 0b01000000
		.byte 0b01000000
		.byte 0b00000000

; $47 - Character: 'G'		CHR$(71)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000010
		.byte 0b01000000
		.byte 0b01001110
		.byte 0b01000010
		.byte 0b00111100
		.byte 0b00000000

; $48 - Character: 'H'		CHR$(72)

		.byte 0b00000000
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01111110
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b00000000

; $49 - Character: 'I'		CHR$(73)

		.byte 0b00000000
		.byte 0b00111110
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00111110
		.byte 0b00000000

; $4A - Character: 'J'		CHR$(74)

		.byte 0b00000000
		.byte 0b00000010
		.byte 0b00000010
		.byte 0b00000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b00111100
		.byte 0b00000000

; $4B - Character: 'K'		CHR$(75)

		.byte 0b00000000
		.byte 0b01000100
		.byte 0b01001000
		.byte 0b01110000
		.byte 0b01001000
		.byte 0b01000100
		.byte 0b01000010
		.byte 0b00000000

; $4C - Character: 'L'		CHR$(76)

		.byte 0b00000000
		.byte 0b01000000
		.byte 0b01000000
		.byte 0b01000000
		.byte 0b01000000
		.byte 0b01000000
		.byte 0b01111110
		.byte 0b00000000

; $4D - Character: 'M'		CHR$(77)

		.byte 0b00000000
		.byte 0b01000010
		.byte 0b01100110
		.byte 0b01011010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b00000000

; $4E - Character: 'N'		CHR$(78)

		.byte 0b00000000
		.byte 0b01000010
		.byte 0b01100010
		.byte 0b01010010
		.byte 0b01001010
		.byte 0b01000110
		.byte 0b01000010
		.byte 0b00000000

; $4F - Character: 'O'		CHR$(79)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b00111100
		.byte 0b00000000

; $50 - Character: 'P'		CHR$(80)

		.byte 0b00000000
		.byte 0b01111100
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01111100
		.byte 0b01000000
		.byte 0b01000000
		.byte 0b00000000

; $51 - Character: 'Q'		CHR$(81)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01010010
		.byte 0b01001010
		.byte 0b00111100
		.byte 0b00000000

; $52 - Character: 'R'		CHR$(82)

		.byte 0b00000000
		.byte 0b01111100
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01111100
		.byte 0b01000100
		.byte 0b01000010
		.byte 0b00000000

; $53 - Character: 'S'		CHR$(83)

		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000000
		.byte 0b00111100
		.byte 0b00000010
		.byte 0b01000010
		.byte 0b00111100
		.byte 0b00000000

; $54 - Character: 'T'		CHR$(84)

		.byte 0b00000000
		.byte 0b11111110
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00000000

; $55 - Character: 'U'		CHR$(85)

		.byte 0b00000000
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b00111100
		.byte 0b00000000

; $56 - Character: 'V'		CHR$(86)

		.byte 0b00000000
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b00100100
		.byte 0b00011000
		.byte 0b00000000

; $57 - Character: 'W'		CHR$(87)

		.byte 0b00000000
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01000010
		.byte 0b01011010
		.byte 0b00100100
		.byte 0b00000000

; $58 - Character: 'X'		CHR$(88)

		.byte 0b00000000
		.byte 0b01000010
		.byte 0b00100100
		.byte 0b00011000
		.byte 0b00011000
		.byte 0b00100100
		.byte 0b01000010
		.byte 0b00000000

; $59 - Character: 'Y'		CHR$(89)

		.byte 0b00000000
		.byte 0b10000010
		.byte 0b01000100
		.byte 0b00101000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00000000

; $5A - Character: 'Z'		CHR$(90)

		.byte 0b00000000
		.byte 0b01111110
		.byte 0b00000100
		.byte 0b00001000
		.byte 0b00010000
		.byte 0b00100000
		.byte 0b01111110
		.byte 0b00000000

; $5B - Character: '['		CHR$(91)

		.byte 0b00000000
		.byte 0b00001110
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001110
		.byte 0b00000000

; $5C - Character: '\'		CHR$(92)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b01000000
		.byte 0b00100000
		.byte 0b00010000
		.byte 0b00001000
		.byte 0b00000100
		.byte 0b00000000

; $5D - Character: ']'		CHR$(93)

		.byte 0b00000000
		.byte 0b01110000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b01110000
		.byte 0b00000000

; $5E - Character: '^'		CHR$(94)

		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00111000
		.byte 0b01010100
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00000000

; $5F - Character: '_'		CHR$(95)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b11111111

; $60 - Character: 'ukp'		 CHR$(96)

		.byte 0b00000000
		.byte 0b00011100
		.byte 0b00100010
		.byte 0b01111000
		.byte 0b00100000
		.byte 0b00100000
		.byte 0b01111110
		.byte 0b00000000

; $61 - Character: 'a'		CHR$(97)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00111000
		.byte 0b00000100
		.byte 0b00111100
		.byte 0b01000100
		.byte 0b00111100
		.byte 0b00000000

; $62 - Character: 'b'		CHR$(98)

		.byte 0b00000000
		.byte 0b00100000
		.byte 0b00100000
		.byte 0b00111100
		.byte 0b00100010
		.byte 0b00100010
		.byte 0b00111100
		.byte 0b00000000

; $63 - Character: 'c'		CHR$(99)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00011100
		.byte 0b00100000
		.byte 0b00100000
		.byte 0b00100000
		.byte 0b00011100
		.byte 0b00000000

; $64 - Character: 'd'		CHR$(100)

		.byte 0b00000000
		.byte 0b00000100
		.byte 0b00000100
		.byte 0b00111100
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b00111100
		.byte 0b00000000

; $65 - Character: 'e'		CHR$(101)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00111000
		.byte 0b01000100
		.byte 0b01111000
		.byte 0b01000000
		.byte 0b00111100
		.byte 0b00000000

; $66 - Character: 'f'		CHR$(102)

		.byte 0b00000000
		.byte 0b00001100
		.byte 0b00010000
		.byte 0b00011000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00000000

; $67 - Character: 'g'		CHR$(103)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b00111100
		.byte 0b00000100
		.byte 0b00111000

; $68 - Character: 'h'		CHR$(104)

		.byte 0b00000000
		.byte 0b01000000
		.byte 0b01000000
		.byte 0b01111000
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b00000000

; $69 - Character: 'i'		CHR$(105)

		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00000000
		.byte 0b00110000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00111000
		.byte 0b00000000

; $6A - Character: 'j'		CHR$(106)

		.byte 0b00000000
		.byte 0b00000100
		.byte 0b00000000
		.byte 0b00000100
		.byte 0b00000100
		.byte 0b00000100
		.byte 0b00100100
		.byte 0b00011000

; $6B - Character: 'k'		CHR$(107)

		.byte 0b00000000
		.byte 0b00100000
		.byte 0b00101000
		.byte 0b00110000
		.byte 0b00110000
		.byte 0b00101000
		.byte 0b00100100
		.byte 0b00000000

; $6C - Character: 'l'		CHR$(108)

		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00001100
		.byte 0b00000000

; $6D - Character: 'm'		CHR$(109)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b01101000
		.byte 0b01010100
		.byte 0b01010100
		.byte 0b01010100
		.byte 0b01010100
		.byte 0b00000000

; $6E - Character: 'n'		CHR$(110)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b01111000
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b00000000

; $6F - Character: 'o'		CHR$(111)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00111000
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b00111000
		.byte 0b00000000

; $70 - Character: 'p'		CHR$(112)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b01111000
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b01111000
		.byte 0b01000000
		.byte 0b01000000

; $71 - Character: 'q'		CHR$(113)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00111100
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b00111100
		.byte 0b00000100
		.byte 0b00000110

; $72 - Character: 'r'		CHR$(114)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00011100
		.byte 0b00100000
		.byte 0b00100000
		.byte 0b00100000
		.byte 0b00100000
		.byte 0b00000000

; $73 - Character: 's'		CHR$(115)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00111000
		.byte 0b01000000
		.byte 0b00111000
		.byte 0b00000100
		.byte 0b01111000
		.byte 0b00000000

; $74 - Character: 't'		CHR$(116)

		.byte 0b00000000
		.byte 0b00010000
		.byte 0b00111000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b00001100
		.byte 0b00000000

; $75 - Character: 'u'		CHR$(117)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b00111000
		.byte 0b00000000

; $76 - Character: 'v'		CHR$(118)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b00101000
		.byte 0b00101000
		.byte 0b00010000
		.byte 0b00000000

; $77 - Character: 'w'		CHR$(119)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b01000100
		.byte 0b01010100
		.byte 0b01010100
		.byte 0b01010100
		.byte 0b00101000
		.byte 0b00000000

; $78 - Character: 'x'		CHR$(120)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b01000100
		.byte 0b00101000
		.byte 0b00010000
		.byte 0b00101000
		.byte 0b01000100
		.byte 0b00000000

; $79 - Character: 'y'		CHR$(121)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b01000100
		.byte 0b00111100
		.byte 0b00000100
		.byte 0b00111000

; $7A - Character: 'z'		CHR$(122)

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b01111100
		.byte 0b00001000
		.byte 0b00010000
		.byte 0b00100000
		.byte 0b01111100
		.byte 0b00000000

; $7B - Character: '{'		CHR$(123)

		.byte 0b00000000
		.byte 0b00001110
		.byte 0b00001000
		.byte 0b00110000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001110
		.byte 0b00000000

; $7C - Character: '|'		CHR$(124)

		.byte 0b00000000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00001000
		.byte 0b00000000

; $7D - Character: '}'		CHR$(125)

		.byte 0b00000000
		.byte 0b01110000
		.byte 0b00010000
		.byte 0b00001100
		.byte 0b00010000
		.byte 0b00010000
		.byte 0b01110000
		.byte 0b00000000

; $7E - Character: '~'		CHR$(126)

		.byte 0b00000000
		.byte 0b00010100
		.byte 0b00101000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000

; $7F - Character: '(c)'		 CHR$(127)

		.byte 0b00111100
		.byte 0b01000010
		.byte 0b10011001
		.byte 0b10100001
		.byte 0b10100001
		.byte 0b10011001
		.byte 0b01000010
		.byte 0b00111100

; "User graphics"

snaketiles::

; $80 - Snake body

		.byte 0b00111100
		.byte 0b01111110
		.byte 0b11111111
		.byte 0b11111111
		.byte 0b11111111
		.byte 0b11111111
		.byte 0b01111110
		.byte 0b00111100

; $81 - Snake head

		.byte 0b00111100
		.byte 0b01111110
		.byte 0b10011001
		.byte 0b11111111
		.byte 0b10011001
		.byte 0b11000011
		.byte 0b01111110
		.byte 0b00111100


; 82 - Food

		.byte 0b01111110
		.byte 0b10000001
		.byte 0b10000001
		.byte 0b10011001
		.byte 0b10011001
		.byte 0b10000001
		.byte 0b10000001
		.byte 0b01111110

; 83 - Grass

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b10000000
		.byte 0b01000010
		.byte 0b00100100
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000

; bad tiles

badtiles::

; $88 - death

		.byte 0b00011000
		.byte 0b00111100
		.byte 0b01111110
		.byte 0b11111111
		.byte 0b11111111
		.byte 0b01111110
		.byte 0b00111100
		.byte 0b00011000

; $89 - dead life

		.byte 0b01000010
		.byte 0b11100111
		.byte 0b01111110
		.byte 0b00111100
		.byte 0b00111100
		.byte 0b01111110
		.byte 0b11100111
		.byte 0b01000010

; wall stuff

walltiles::

; $90 - top

		.byte 0b11111111
		.byte 0b11111111
		.byte 0b11111111
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000

; $91 - top right

		.byte 0b11111100
		.byte 0b11111110
		.byte 0b11111111
		.byte 0b00011111
		.byte 0b00001111
		.byte 0b00000111
		.byte 0b00000111
		.byte 0b00000111

; $92 - right

		.byte 0b00000111
		.byte 0b00000111
		.byte 0b00000111
		.byte 0b00000111
		.byte 0b00000111
		.byte 0b00000111
		.byte 0b00000111
		.byte 0b00000111

; $93 - bottom right

		.byte 0b00000111
		.byte 0b00000111
		.byte 0b00000111
		.byte 0b00001111
		.byte 0b00011111
		.byte 0b11111111
		.byte 0b11111110
		.byte 0b11111100

; $94 - bottom

		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b00000000
		.byte 0b11111111
		.byte 0b11111111
		.byte 0b11111111

; $95 - bottom left

		.byte 0b11100000
		.byte 0b11100000
		.byte 0b11100000
		.byte 0b11110000
		.byte 0b11111000
		.byte 0b11111111
		.byte 0b01111111
		.byte 0b00111111

; $96 - left

		.byte 0b11100000
		.byte 0b11100000
		.byte 0b11100000
		.byte 0b11100000
		.byte 0b11100000
		.byte 0b11100000
		.byte 0b11100000
		.byte 0b11100000

; $97 - top left

		.byte 0b00111111
		.byte 0b01111111
		.byte 0b11111111
		.byte 0b11111000
		.byte 0b11110000
		.byte 0b11100000
		.byte 0b11100000
		.byte 0b11100000

colours::

; Speccy font tiles

		.byte 0x10
		.byte 0x10
		.byte 0x10
		.byte 0x10

		.byte 0x10
		.byte 0x10
		.byte 0x10
		.byte 0x10

		.byte 0x10
		.byte 0x10
		.byte 0x10
		.byte 0x10

		.byte 0x10
		.byte 0x10
		.byte 0x10
		.byte 0x10

; "Graphics"

		.byte 0x30		; green snake
		.byte 0x80		; red bad things
		.byte 0x10		; border
		.byte 0x30

		.byte 0x30
		.byte 0x30
		.byte 0x30
		.byte 0x30

		.byte 0x30
		.byte 0x30
		.byte 0x30
		.byte 0x30

		.byte 0x30
		.byte 0x30
		.byte 0x30
		.byte 0x30
