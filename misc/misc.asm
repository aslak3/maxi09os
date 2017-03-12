;;; MISC ;;;

		.area ROM

; delay by y

delay::		leay -1,y		; decrement y
		bne delay		; not zero? do it again
		rts

; wordswap - swap the bytes in the word pointed to by x

wordswap::	pshs a,b
		ldd ,x			; grab the word that we wills wap
		exg a,b			; swap the bytes
		std ,x			; save what's swapped
		puls a,b
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

memcpy256::	pshs b,x,y
1$:		ldb ,x+			; get the source byte
		stb ,y+			; save it
		deca			; dec the number of bytes to copy
		bne 1$			; back for more?
		puls b,x,y
		rts
