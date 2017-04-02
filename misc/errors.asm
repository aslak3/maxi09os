;;; ERROR NUMBERS ;;;

		.area ROM

okz:		.asciz 'Ok (no error)'
generalz:	.asciz 'Failure'
parserfailz:	.asciz 'Parser error'
notadirz:	.asciz 'Not a directory'
notfoundz:	.asciz 'Not found'
internalz:	.asciz 'Internal error'

errortable:	.word okz
		.word generalz
		.word parserfailz
		.word notadirz
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
