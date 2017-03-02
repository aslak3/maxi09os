; v99(58) low level routines

		.include '../include/system.inc'
		.include '../include/hardware.inc'
		.include '../include/v99lowlevel.inc'
		.include '../include/debug.inc'

		.area ROM

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

vinit::		pshs a
		clra			; disable the extension bank
		loadareg VBANKREG
		lda #0x08		; position screen in the middle
		loadareg VDISPLAYPOSREG
		clra
		loadareg VDISPLAYOFFREG
		clra
		loadareg VINTLINEREG
		puls a
		rts

; writes to y in vram, count u bytes, from x in mpu ram

vwrite::	pshs y,a
		lbsr vseekwrite		; seek to y for writing
		tfr u,y			; leau does not set z, so need y
1$:		lda ,x+			; get byte from mpu ram
		writeaport0		; save it to the vdc
		leay -1,y		; decrement
		bne 1$			; back for more?
		puls y,a
		rts

; clears (zero) to y in vram, count u bytes

vclear::	pshs y,a
		lbsr vseekwrite		; seek to y for writing
		tfr u,y			; leau does not set z, so need y
		clra			; we are clearing
1$:		writeaport0		; clear the byte in vram
		leay -1,y		; decrement counter
		bne 1$			; back for more?
		puls y,a
		rts

; reads into x in mpu, count u bytes, from y in vram

vread::		pshs y,a
		lbsr vseekread
		tfr u,y			; leau does not set z, so need y
1$:		readaport0		; get the vram byte
		sta ,x+			; sve in mpu ram
		leay -1,y		; dec counter
		bne 1$			; back for more?
		puls y,a
		rts

; seek to vram address y for writing

vseekwrite::	pshs a,b
		lbsr vseekcommon	; common address register stuff
		ora #0b01000000		; set writing mode
		sta VADDRPORT		; write last vram address byte
		sleep			; have a nop nap
		puls a,b
		rts

; seek to vram address at y for reading

vseekread::	pshs a,b
		lbsr vseekcommon	; common addess register stuff
		sta VADDRPORT		; save the last byte
		sleep			; nop nap
		puls a,b
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

