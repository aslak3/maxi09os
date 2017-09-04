; idler task implementation

		.globl sysopen
		.globl syswrite
		.globl delay

		.area ROM

; idler task

leddevice:	.asciz 'led'

_idler::	ldx #leddevice		; get the led device name
		lbsr sysopen		; open it
1$:		lda #1			; on
		lbsr syswrite		; make the led turn on
		ldy #0x6000		; delay for a "reasonable" time
		lbsr delay		; and delay
		clra			; off
		lbsr syswrite		; make the led turn off
		ldy #0x6000		; delay for a "reasonable" time
		lbsr delay		; and delay
		bra 1$			; and back for more, forever
