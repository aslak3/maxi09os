; Main snake source

		.include '../include/subtable.inc'

		.include '../../include/ascii.inc'
		.include '../../include/hardware.inc'
		.include '../../include/v99lowlevel.inc'

		.globl clearscreen
		.globl clearplayarea
		.globl drawplayarea
		.globl defaultlives
		.globl showlives

		.globl joydevice

calibrate::	lbsr clearscreen	; clear scren at the start
		lbsr drawplayarea	; draw the border
		lbsr clearplayarea	; clear the middle of the screen
		lbsr defaultlives	; reset the number of lives
		lbsr showlives		; show the number of lives

		clrb

calibrateloop:	tfr b,a
		loadareg VDISPLAYPOSREG 

		ldx joydevice,pcr
		jsr [getchar]
		bita #JOYFIRE1
		bne calibrateo
		bita #JOYLEFT
		bne calibrateleft
		bita #JOYRIGHT
		bne calibrateright
		bita #JOYUP
		bne calibrateup
		bita #JOYDOWN
calibratenext:	bra calibrateloop

calibrateo:	rts

calibrateleft:	incb
		bra calibratenext
calibrateright:	decb
		bra calibratenext
calibrateup:	addb #0x10
		bra calibratenext
calibratedown:	subb #0x10
		bra calibratenext		
