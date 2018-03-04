; Main snake source

                .include '../include/subtable.inc'

                .include '../../include/ascii.inc'
                .include '../../include/hardware.inc'
		.include '../../include/system.inc'

		.globl videoinit
		.globl clearscreen
		.globl printstrat
		.globl calibrate
		.globl game
		.globl demoprepare
		.globl demosnakemove

start::		leax timerz,pcr		; the timer string
		jsr [sysopen]		; open the timer
		stx timerdevice,pcr	; save the handle
		lda DEVICE_SIGNAL,x	; get the signal bit
		sta timersignal,pcr	; save it away

		leax joyz,pcr		; the joy string
		clra			; we want port 0
		jsr [sysopen]		; open the joystick
		stx joydevice,pcr	; save the handle
		lda DEVICE_SIGNAL,x	; get the signal bit
		sta joysignal,pcr	; save it away

		lbsr videoinit		; set 32x24 tile mode

		leax videoinit,pcr	; the address of above sub
		jsr [setgraphicsub]	; save it as f10 graphic sub

menu:		ldd #15			; 15/40 of a sec
		std timerperiod,pcr	; set it in control block
		ldx timerdevice,pcr	; get timer device
		leay timercontrol,pcr	; get timer block
		lda #TIMERCMD_START	; start timer
		jsr [syscontrol]	; start 0.5sec timer

		lbsr clearscreen	; clear the screen

		lda #9			; y
		ldb #3			; x
		leax pressfirez,pcr	; press fire mssage
		lbsr printstrat		; print the message

		lda #11			; ...
		ldb #3			; ...
		leax orexitz,pcr	; or exit with up
		lbsr printstrat		; ...

		lda #13			; ...
		ldb #3			; ...
		leax orcalibratez,pcr	; or calibrate with down
		lbsr printstrat		; ...

		lbsr demoprepare	; prepare the demo snake

menuloop:	lda timersignal,pcr	; get the signal bit
		ora joysignal,pcr	; or in the joystick sigbit
                jsr [wait]		; wait for the half sec

		bita timersignal,pcr	; check the timer
		bne timersig		; handle the timer

		bita joysignal,pcr	; check the timer
		bne joysig		; handle the timer

		bra menuloop		; unknown sig

timersig:	lbsr demosnakemove	; move the demo snake

		bra menuloop		; back up to poll

joysig:		ldx joydevice,pcr	; get stick state
		jsr [sysread]
		bne menuloop		; no event yet?
		bita #JOYFIRE1		; fire?
		bne startgame		; if pressed then start
		bita #JOYUP		; up?
		bne exit		; if up then exit
		bita #JOYDOWN		; down?
		bne startcalibrate	; if down then calibrate

		bra menuloop

startgame:	lbsr game		; run game as subroutine

		bra menu		; end game, show menu

startcalibrate:	lbsr calibrate		; run calibrate sub

		bra menu		; then back to showing menu

exit:		ldx timerdevice,pcr	; get the timer
		jsr [sysclose]		; close it
		ldx joydevice,pcr	; get the joystick
		jsr [sysclose]		; close it

		ldx #0			; reset graphic sub callback
		jsr [setgraphicsub]	; set it

		rts			; back to the shell

pressfirez:	.asciz 'Press FIRE to start'
orexitz:	.asciz 'Or UP to exit'
orcalibratez:	.asciz 'Or DOWN to position screen'

timerz:		.asciz 'timer'
joyz:		.asciz 'joy'

timerdevice::	.rmb 2			; open timer device (global)
timersignal::	.rmb 1			; signal bit

joydevice::	.rmb 2			; open joy device (global)
joysignal::	.rmb 1			; signal bit

timercontrol::	.byte 1			; repeating timer
timerperiod::	.word 0			; rewritten as needed

dummy:		.byte 0
