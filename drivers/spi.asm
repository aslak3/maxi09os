; spi driver

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl memoryalloc
		.globl memoryfree
		.globl signalalloc
		.globl forbid
		.globl permit

		.globl _devicenotimp

SPIUNUSED	.equ 0xff

structstart	DEVICE_SIZE
structend	SPI_SIZE

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
		clr SPIOUT		; clear clock and mosi
		sta SPISELECTS		; set the selects
		ldx #SPI_SIZE		; allocate device block
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
		clr SPIOUT		; clear clock and mosi
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

; spiread - read a byte into a for the open spi device

spiread:	pshs b
		clra			; clear the read byte

; bit 7

		ldb #SCLK		; clock high ...
		stb SPIOUT		; ... set it
		ldb SPIIN		; get state of miso
		rorb			; rotate into carry
		rola			; rotate back into a
		clr SPIOUT		; clock low

; bit 6

		ldb #SCLK		; clock high ...
		stb SPIOUT		; ... set it
		ldb SPIIN		; get state of miso
		rorb			; rotate into carry
		rola			; rotate back into a
		clr SPIOUT		; clock low


; bit 5

		ldb #SCLK		; clock high ...
		stb SPIOUT		; ... set it
		ldb SPIIN		; get state of miso
		rorb			; rotate into carry
		rola			; rotate back into a
		clr SPIOUT		; clock low


; bit 4

		ldb #SCLK		; clock high ...
		stb SPIOUT		; ... set it
		ldb SPIIN		; get state of miso
		rorb			; rotate into carry
		rola			; rotate back into a
		clr SPIOUT		; clock low

; bit 3

		ldb #SCLK		; clock high ...
		stb SPIOUT		; ... set it
		ldb SPIIN		; get state of miso
		rorb			; rotate into carry
		rola			; rotate back into a
		clr SPIOUT		; clock low

; bit 2

		ldb #SCLK		; clock high ...
		stb SPIOUT		; ... set it
		ldb SPIIN		; get state of miso
		rorb			; rotate into carry
		rola			; rotate back into a
		clr SPIOUT		; clock low

; bit 1

		ldb #SCLK		; clock high ...
		stb SPIOUT		; ... set it
		ldb SPIIN		; get state of miso
		rorb			; rotate into carry
		rola			; rotate back into a
		clr SPIOUT		; clock low

; bit 0

		ldb #SCLK		; clock high ...
		stb SPIOUT		; ... set it
		ldb SPIIN		; get state of miso
		rorb			; rotate into carry
		rola			; rotate back into a
		clr SPIOUT		; clock low

		setzero
		puls b
		rts

; spiwrite - send the byte in a

spiwrite:	pshs b

; bit 7

		clrb			; start from nothing
		lsla			; move the bit to send into carry
		adcb #0			; add carry so low bit is set for out
		stb SPIOUT		; output
		orb #SCLK		; assert the clock by oring it in
		stb SPIOUT		; output
		eorb #SCLK		; clear the clock
		stb SPIOUT		; output

; bit 6

		clrb			; start from nothing
		lsla			; move the bit to send into carry
		adcb #0			; add carry so low bit is set for out
		stb SPIOUT		; output
		orb #SCLK		; assert the clock by oring it in
		stb SPIOUT		; output
		eorb #SCLK		; clear the clock
		stb SPIOUT		; output

; bit 5

		clrb			; start from nothing
		lsla			; move the bit to send into carry
		adcb #0			; add carry so low bit is set for out
		stb SPIOUT		; output
		orb #SCLK		; assert the clock by oring it in
		stb SPIOUT		; output
		eorb #SCLK		; clear the clock
		stb SPIOUT		; output

; bit 4

		clrb			; start from nothing
		lsla			; move the bit to send into carry
		adcb #0			; add carry so low bit is set for out
		stb SPIOUT		; output
		orb #SCLK		; assert the clock by oring it in
		stb SPIOUT		; output
		eorb #SCLK		; clear the clock
		stb SPIOUT		; output

; bit 3

		clrb			; start from nothing
		lsla			; move the bit to send into carry
		adcb #0			; add carry so low bit is set for out
		stb SPIOUT		; output
		orb #SCLK		; assert the clock by oring it in
		stb SPIOUT		; output
		eorb #SCLK		; clear the clock
		stb SPIOUT		; output

; bit 2

		clrb			; start from nothing
		lsla			; move the bit to send into carry
		adcb #0			; add carry so low bit is set for out
		stb SPIOUT		; output
		orb #SCLK		; assert the clock by oring it in
		stb SPIOUT		; output
		eorb #SCLK		; clear the clock
		stb SPIOUT		; output

; bit 1

		clrb			; start from nothing
		lsla			; move the bit to send into carry
		adcb #0			; add carry so low bit is set for out
		stb SPIOUT		; output
		orb #SCLK		; assert the clock by oring it in
		stb SPIOUT		; output
		eorb #SCLK		; clear the clock
		stb SPIOUT		; output

; bit 0

		clrb			; start from nothing
		lsla			; move the bit to send into carry
		adcb #0			; add carry so low bit is set for out
		stb SPIOUT		; output
		orb #SCLK		; assert the clock by oring it in
		stb SPIOUT		; output
		eorb #SCLK		; clear the clock
		stb SPIOUT		; output

		setzero
		puls b
		rts
