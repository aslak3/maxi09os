; set the time and date

		.include 'include/subtable.inc'

		.include '../include/ascii.inc'
		.include '../include/hardware.inc'

settime:	leay promptmsg,pcr	; output a overview message
		jsr [putstr]		; ...

		leau spibuffer,pcr	; setup the spi data buffer

		leay hourmsg,pcr	; prompt for the hour
		jsr [putstr]		; output the prompt
		lbsr getbyte		; get a byte into a
		sta 2,u			; save it in the spi buffer

		leay minmsg,pcr		; ...
		jsr [putstr]		; ...
		lbsr getbyte		; ...
		sta 1,u			; ...

		leay secmsg,pcr
		jsr [putstr]
		lbsr getbyte
		sta 0,u

		leay daymsg,pcr
		jsr [putstr]
		lbsr getbyte
		sta 4,u

		leay monthmsg,pcr
		jsr [putstr]
		lbsr getbyte
		sta 5,u

		leay yearmsg,pcr
		jsr [putstr]
		lbsr getbyte
		sta 6,u

		leay dayofweekmsg,pcr
		jsr [putstr]
		lbsr getbyte
		sta 3,u

		lda #SPICLOCK		; we want the clock
		leax spiz,pcr		; we want spi
		jsr [sysopen]		; open it

		lda #0x80		; write into location 00
		jsr [syswrite]		; which is where the time/date go

		leay spibuffer,pcr	; setup the spi data buffer
		ldu #7			; 3 for time, 3 for date 1 for day
		jsr [putchars]		; write them to the rtc spi ic

		jsr [sysclose]		; close the spi device

		clra			; set subroutine result
		
		rts

; getbyte - read a string of input via the x device and convert it to a byte 
; value, which will go in the a register

getbyte:	pshs y
		leay linebuffer,pcr	; get the input buffer
		jsr [getstr]		; read it in
		exg y,x			; we need it in x to convert
		jsr [aschextobyte]	; convert it to a byte value
		exg x,y			; put x back for the io device
		puls y
		rts

; constants

spiz:		.asciz "spi"

; variables

spibuffer:	.rmb 7			; the rtc register/memory bytes
linebuffer:	.rmb 100		; for getting a byte

; messages

promptmsg:	.asciz "Enter the time and date:\r\n\r\n"
hourmsg:	.asciz "Hour? (00-23) "
minmsg:		.asciz "Minute? (00-59) "
secmsg:		.asciz "Second? (00-59) "
daymsg:		.asciz "Day? (01-31) "
monthmsg:	.asciz "Month? (01-12) "
yearmsg:	.asciz "Year? (00-99) "
dayofweekmsg:	.asciz "Day number? (01=Sun-07=Sat) "
