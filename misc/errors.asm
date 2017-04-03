;;; ERROR NUMBERS ;;;

		.area ROM

okz:		.asciz 'Ok (no error)'
generalz:	.asciz 'Failure'
parserfailz:	.asciz 'Parser error'
notdirz:	.asciz 'Not a directory'
notregularz:	.asciz 'Not a regular file'
notfoundz:	.asciz 'Not found'
internalz:	.asciz 'Internal error'

errortable:	.word okz
		.word generalz
		.word parserfailz
		.word notdirz
		.word notregularz
		.word notfoundz
		.word internalz	

; geterrorstr - gets the error string by looking in the error table,
; and putting the 

geterrorstr::	pshs a
		lsla			; table is of words
		ldy #errortable		; set the string table base address
		ldy a,y			; get the string address
		puls a
		rts
