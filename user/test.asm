		.include '../include/hardware.inc'
		.include '../include/autogen.inc'

		.area RAM (ABS)

		.org 0			; always pc relative

start:		leay promptz,pcr	; load prompt addr
		jsr putstr		; display prompt
		leay data,pcr		; get data
		jsr getstr		; get the string
		leay helloz,pcr		; say ...
		jsr putstr		; ... hello
		leay data,pcr		; get name
		jsr putstr		; and print it
		ldy #newlinez		; tidy up with a newline
		jsr putstr		; ...

		lda #0x47		; 42 with inflation
		rts

promptz:	.asciz 'What is your name? '
helloz:		.asciz 'Hello '
data:		.rmb 100
