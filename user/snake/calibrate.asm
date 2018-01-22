; Main snake source

		.include '../include/subtable.inc'

		.include '../../include/ascii.inc'
		.include '../../include/hardware.inc'
		.include '../../include/v99lowlevel.inc'

		.globl clearscreen
		.globl drawplayarea
		.globl readjoystick

calibrate::	lbsr clearscreen	; clear scren at te start
		lbsr drawplayarea	; draw the border

		clrb

calibrateloop:	leay 0x8000,y
		jsr [delay]

		tfr b,a
		loadareg VDISPLAYPOSREG 

		lbsr readjoystick
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

calibrateo:	ldy #0x0000
		jsr [delay]

		rts

calibrateleft:	incb
		bra calibratenext
calibrateright:	decb
		bra calibratenext
calibrateup:	addb #0x10
		bra calibratenext
calibratedown:	subb #0x10
		bra calibratenext		
