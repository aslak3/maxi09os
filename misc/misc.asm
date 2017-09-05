;;; MISC ;;;

		.area ROM

; constants

_newlinez::	.asciz '\r\n'

; delay by y

delay::		leay -1,y		; decrement y
		bne delay		; not zero? do it again
		rts

; swapword - swap the bytes in the word at x

swapword:: 	pshs a,b
		ldd ,x			; grab the word that we wills wap
		exg a,b			; swap the bytes
		std ,x			; save what's swapped
		puls a,b
		rts

; swaplong - swap the words in the long x

swaplong::	pshs a,b,u
		ldu 2,x			; get the high word
		ldd ,x			; get the low word
		exg a,b			; swap the low word bytes
		std 2,x			; save the low word, swapped
		tfr u,d			; get the high word
		exg a,b			; swap the high word bytes
		std ,x			; save the high word, swapped
		puls a,b,u
		rts

; div32 - divide d by 32

div32::		lsra
		rorb
		lsra
		rorb
		lsra
		rorb
		lsra
		rorb
		lsra
		rorb			; / 32
		rts

; mul32 - multiply d by 32

mul32::		lslb
		rola
		lslb
		rola
		lslb
		rola
		lslb
		rola
		lslb
		rola			; * 32
		rts

; memory copy - x is source, y is destination, a is length

memcpy256::	pshs b,x,y		; save address inputs
1$:		ldb ,x+			; get the source byte
		stb ,y+			; save it
		deca			; dec the number of bytes to copy
		bne 1$			; back for more?
		puls b,x,y		; restore address inputs
		rts
