; Main snake source

                .include '../include/subtable.inc'

                .include '../../include/ascii.inc'
                .include '../../include/hardware.inc'

		.globl videoinit
		.globl clearscreen
		.globl printstrat
		.globl calibrate
		.globl game

start::		lbsr videoinit			; set 32x24 tile mode

		leax videoinit,pcr		; the address of above sub
		jsr [setgraphicsub]		; save it as f10 graphic sub

menu:		lbsr clearscreen		; clear the screen

		lda #9				; y
		ldb #2				; x
		leax pressfirez,pcr		; press fire mssage
		lbsr printstrat			; print the message

		lda #11				; ...
		ldb #2				; ...
		leax orexitz,pcr		; or exit with up
		lbsr printstrat			; ...

		lda #13				; ...
		ldb #2				; ...
		leax orcalibratez,pcr		; or calibrate with down
		lbsr printstrat			; ...

menupollloop:	lbsr readjoystick		; get stick state
		bita #JOYFIRE1			; fire?
		bne startgame			; if pressed then start
		bita #JOYUP			; up?
		bne exit			; if up then exit
		bita #JOYDOWN			; down?
		bne startcalibrate		; if down then calibrate

		bra menupollloop		; back up to poll

startgame:	lbsr game			; run game as subroutine

		bra menu			; end game, show menu

startcalibrate:	lbsr calibrate			; run calibrate sub

		bra menu			; then back to showing menu

exit:		ldx #0				; reset graphic sub callback
		jsr [setgraphicsub]		; set it

		rts				; back to the shell

pressfirez:	.asciz 'Press FIRE to start'
orexitz:	.asciz 'Or UP to exit'
orcalibratez:	.asciz 'Or DOWN to calibrate screen'

readjoystick::	lda JOYPORT0			; read joystick state
		coma				; invert, 1=pressed/pushed
		rts
