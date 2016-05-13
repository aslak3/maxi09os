;;; MISC ;;;

; delay by y - subroutine

delay:		leay -1,y		; decrement y
		bne delay		; not zero? do it again
		rts

; wordswap

wordswap:	pshs d
		ldd ,x
		exg a,b
		std ,x
		puls d
		rts

; div32

div32:		lsra
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

; mul32

mul32:		lslb
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
