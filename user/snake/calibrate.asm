; Main snake source

		.include '../include/subtable.inc'

		.include '../../include/ascii.inc'
		.include '../../include/hardware.inc'
		.include '../../include/v99lowlevel.inc'

		.globl clearscreen
		.globl drawplayarea
		.globl clearplayarea
		.globl defaultlives
		.globl showlives

		.globl joydevice

vidpos:		.byte 0			; video position (updated)

calibrate::	lbsr clearscreen	; clear scren at the start
		lbsr drawplayarea	; draw the border
		lbsr clearplayarea	; clear the middle of the screen
		lbsr defaultlives	; reset the number of lives
		lbsr showlives		; show the number of lives

		ldb vidpos,pcr		; get current position

calibrateloop:	tfr b,a			; transfer position to a
		loadareg VDISPLAYPOSREG	; assert position in the vdc

		ldx joydevice,pcr	; get the joystick dev
		jsr [getchar]		; wait for one byte
		bita #JOYFIRE1		; checking for fire ...
		bne calibrateo		; ... if pressed, jump out
		bita #JOYLEFT		; ...
		bne calibrateleft	; pan screen left
		bita #JOYRIGHT		; ...
		bne calibrateright	; pan screen right
		bita #JOYUP		; ...
		bne calibrateup		; pan screen up
		bita #JOYDOWN		; ...
		bra calibrateloop	; back to the top

calibrateo:	stb vidpos,pcr		; on the way out save the pos in ram
		rts

calibrateleft:	incb			; low nibble is horizontal
		bra calibrateloop	; assert new position
calibrateright:	decb			; ...
		bra calibrateloop	; ...
calibrateup:	addb #0x10		; high bibble is verticle
		bra calibrateloop	; assert new posiion
calibratedown:	subb #0x10		; ...
		bra calibrateloop	; ...
