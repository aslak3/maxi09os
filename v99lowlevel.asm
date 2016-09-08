; v99(58) low level routines

		.include 'hardware.inc'

		.area ROM

; simple timing delay

.macro		sleep
		nop
		nop
		nop
.endm

; stores whats in register a in the v99 register

.macro		loadareg register
		sta VDIRECTPORT
		lda #register|0x80
		sta VDIRECTPORT
.endm

; stores the value in the v99 register

.macro		loadconstreg register, value
		lda #value
		sta VDIRECTPORT
		lda #register|0x80
		sta VDIRECTPORT
.endm

; gets the value of the status register

.macro		getstatusreg register
		lda #register
		loadareg VSTATUSREG
		lda VSTATUSPORT
.endm

; save into the registers, starting from the register in a. the value
; pointed by x and counted by y are copied in

vindirect::	ora #0x80		; auto incmreneting mode
		loadareg VINDIRECTREG	; set up the indirect reg
1$:		lda ,x+			; get the value
		sta VINDIRECTPORT	; save it in the register
		leay -1,y		; dec the counter
		bne 1$			; see if there is more
		rts

; sets the colour in a to the r g b pointed to by x

vsetcolour::	pshs a			; save the current colour
		loadareg VPALETTEREG	; we are writing to the colour reg
		lda ,x+			; get red
		lsla			; move it to the high nibble
		lsla			; ..
		lsla			; ..
		lsla			; ..
		ldb ,x+			; next, put green in b
		ora ,x+			; or in blue over red
		sta VPALETTEPORT	; output red and blue
		stb VPALETTEPORT	; output green
		puls a			; get the colour back
		rts

; set the colours - x points at r g b list, y sets the number of colours to
; set

vsetcolours::	clra			; start from col 0
1$:		bsr vsetcolour		; sets this colour
		inca			; next colour
		leay -1,y		; dec the count of colours
		bne 1$			; more?
		rts

; sets up "core" registers

vinit::		pshs a,y,u
		loadconstreg VBANKREG, 0x00
		loadconstreg VDISPLAYPOSREG, 0x08
		loadconstreg VDISPLAYOFFREG, 0x00
		loadconstreg VINTLINEREG, 0x00

		ldy #0x0000		; vram start address
		ldu #0x0000		; length
		lbsr vclear		; clear 64KB
		puls a,y,u
		rts

; writes to y in vram, count u bytes, from x in mpu ram

vwrite::	pshs y,a
		lbsr vseekwrite		; seek to y for writing
		tfr u,y			; leau does not set z, so need y
1$:		lda ,x+			; get byte from mpu ram
		sta VPORT0		; save it to the vdc
		leay -1,y		; decrement
		bne 1$			; back for more?
		puls y,a
		rts

; clears (zero) to y in vram, count u bytes

vclear::	pshs y,a
		lbsr vseekwrite		; seek to y for writing
		tfr u,y			; leau does not set z, so need y
		clra			; we are clearing
1$:		sta VPORT0		; clear the byte in vram
		leay -1,y		; decrement counter
		bne 1$			; back for more?
		puls y,a
		rts

; reads into x in mpu, count u bytes, from y in vram

vread::		pshs y,a
		lbsr vseekread
		tfr u,y			; leau does not set z, so need y
1$:		lda VPORT0		; get the vram byte
		sta ,x+			; sve in mpu ram
		leay -1,y		; dec counter
		bne 1$			; back for more?
		puls y,a
		rts

; prepare the vdc for reading or writing from y in vram

vseekcommon:	tfr y,d			; we need to do some shifting
		lsra
		lsra
		lsra
		lsra
		lsra
		lsra			; six shifts put a15 at bit 1
		loadareg VADDRREG
		tfr y,d			; retore original address
		stb VADDRPORT		; the low 8 bits of address (easy)
		anda #0b00111111	; mask out the high two bits
		rts

; seek to vram address y for writing

vseekwrite::	pshs a,b
		lbsr vseekcommon
		ora #0b01000000		; set writing mode
		sta VADDRPORT		; write last vram address byte
		sleep			; have a nop nap
		puls a,b
		rts

; seek to vram address at y for reading

vseekread::	lbsr vseekcommon
		sta VADDRPORT
		sleep
		rts
