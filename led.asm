; led driver

		.include 'system.inc'
		.include 'hardware.inc'

		.area RAM

ledinuse:	.rmb 1			; 1 for open, 0 for closed

		.area ROM

leddef::	.word ledopen
		.word 0x0000
		.asciz "led"

; led open

ledopen:	lbsr disable		; enter critical section
		lda ledinuse
		bne 1$			; in use?
		lda #1			; mark it as being in use
		sta ledinuse		; ...
		ldx #DEVICE_SIZE	; allocate the device struct
		lbsr memoryalloc	; get the memory for the struct
		ldy #ledclose		; save the close pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #ledwrite		; save the write pointer
		sty DEVICE_WRITE,x	; ... in the device struct
		ldy #devicenotimpl	; not implemented
		sty DEVICE_SEEK,x	; seek
		sty DEVICE_CONTROL,x	; and control
		lbsr enable		; exit critical section
		setnotzero
		rts
1$:		lbsr enable		; exit critical section
		ldx #0			; return 0
		setzero			; port is in use
		rts

; led close - give it the device in x

ledclose:	lbsr disable
		clr ledinuse		; mark it unused
		lbsr memoryfree		; free the open device handle
		lbsr enable
		rts

; write to the device in x, reg a

ledwrite:	sta LED			; on or off, it's in a
		setzero
		rts
