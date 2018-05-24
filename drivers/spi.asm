; spi driver

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl memoryalloc
		.globl memoryfree
		.globl forbid
		.globl permit

		.globl _devicenotimp

SPIUNUSED	.equ 0xff		; spi device isn't open

		.area RAM

spiunit:	.rmb 1			; 0xff for not in use

		.area ROM

_spidef::	.word spiopen
		.word spiprepare
		.asciz "spi"

spiprepare:	pshs a
		lda #SPIUNUSED		; mark unused ...
		sta spiunit		; ... and not open
		puls a
		rts

; spiopen - a contains the unit number, which maps (in disco) to a
; particular combination of slave select lines being turned on or off.

spiopen:	pshs b,y
		lbsr forbid		; enter critical section
		ldb spiunit		; see if spi is open
		cmpb #SPIUNUSED		; used?
		bne 1$			; yes, so out we go
		sta spiunit		; ... as being in use
		sta SPISELECTS		; set the selects
		ldx #DEVICE_SIZE	; allocate device block
		lbsr memoryalloc	; get the block
		ldy #spiclose		; save the close pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #spiread		; save the read pointer
		sty DEVICE_READ,x	; ... in the device struct
		ldy #spiwrite		; save the write pointer
		sty DEVICE_WRITE,x	; ... in the device struct
		ldy #spicontrol		; save the control pointer
		sty DEVICE_CONTROL,x	; ... in the device struct
		ldy #_devicenotimp	; not implemented
		sty DEVICE_SEEK,x	; seek
		setzero
		bra 2$
1$:		ldx #0			; return 0
		setnotzero		; port is in use
2$:		lbsr permit		; exit critical section
		puls b,y
		rts

; spiclose - give it the device in x

spiclose:	pshs a
		lbsr forbid
		lda #SPIUNUSED		; set the "unused" select value
		sta SPISELECTS		; write it into the register
		sta spiunit		; mark host controller not in use
		lbsr memoryfree		; free the open device handle
		lbsr permit
		puls a
		rts

; spicontrol - only one action, turn off all spi devices, then tuen the
; one which was opened for this device back on. this allows another
; data exchange without closing and opening the device

spicontrol:	pshs a
		lda #SPIUNUSED		; turn off all slave selects
		sta SPISELECTS		; write it to the spi controller
		lda spiunit		; get the active unit
		sta SPISELECTS		; and turn the current one back on
		puls a
		rts

; spiread and spiwrite - read and write a byte into the open spi device
; this busy waits while disco shifts the byte out (and in). this is
; simpler then polling a status bit in a register. [ each poll
; will take 8 cycles (lda; bpl), against 16 ticks to shift a byte
; in disco. so this will be done some day ]
spiread:	clra			; for reads send a zero
spiwrite:	sta SPIOUT		; force 8 bits out
		nop			; now do 8 nops ...
		nop			; ... 2 clocks per nop
		nop			; spi clock runs at 2 ticks ...
		nop			; ... per bit transfererd
		nop			; so after 8 nops ... 
		nop			; ... a byte has been sent
		nop			; and ...
		nop			; ... a byte has been is vailable
		lda SPIIN		; for reading too
		setzero
		rts
