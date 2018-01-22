; Main snake source

                .include '../include/subtable.inc'

                .include '../../include/ascii.inc'
                .include '../../include/hardware.inc'

		.globl videoinit
		.globl clearscreen
		.globl printstrat
		.globl readjoystick
		.globl calibrate
		.globl game

start::		lbsr videoinit

		leax videoinit,pcr
		jsr [setgraphicsub]

menu:		lbsr clearscreen

		lda #9
		ldb #2
		leax pressfire,pcr
		lbsr printstrat

		lda #11
		ldb #2
		leax orexit,pcr
		lbsr printstrat

		lda #13
		ldb #2
		leax orcalibrate,pcr
		lbsr printstrat

menupollloop:	lbsr readjoystick
		bita #JOYFIRE1
		bne startgame
		bita #JOYUP
		bne exit
		bita #JOYDOWN
		bne startcalibrate

		bra menupollloop

startgame:	lbsr game

		bra menu

startcalibrate:	lbsr calibrate

		bra menu

exit:		ldx #0
		jsr [setgraphicsub]
		rts

pressfire:	.asciz 'Press FIRE to start'
orexit:		.asciz 'Or UP to exit'
orcalibrate:	.asciz 'Or DOWN to calibrate screen'

readjoystick:	lda JOYPORT0
		coma
		rts
