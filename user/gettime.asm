; get the time from the  clock and print it

		.include 'include/subtable.inc'

		.include '../include/ascii.inc'
		.include '../include/hardware.inc'

gettime:	leax spiz,pcr		; we want spi
		lda #SPICLOCK		; we want the clock
		jsr [sysopen]		; open it
		stx spidevice,pcr	; save it in a variable

		lda #0x00		; read from address 0
		jsr [syswrite]		; send the read address

		leay timeoutput,pcr	; read into this buffer
		ldu #7			; we need 7 bytes

		jsr [getchars]		; get u bytes into y

		jsr [sysclose]		; close the spi device

		leax outputbuffer,pcr	; setup output buffer
		leay timeoutput,pcr	; setup rtc data buffer

		lda 2,y			; get hours
		jsr [bytetoaschex]	; render hex into x
		lda #0x3a		; ':'
		sta ,x+			; add the colon in
		lda 1,y			; get minutes
		jsr [bytetoaschex]	; render hex into x
		lda #0x3a		; ':'
		sta ,x+			; add the colon in
		lda 0,y			; get seconds
		jsr [bytetoaschex]	; render hex into x
		lda #0x20		; space char
		sta ,x+			; add the space in

		lda 3,y			; get days (1-7)
		deca			; make it into 0-6
		lsla			; multiply by 4 as each day is 4...
		lsla			; bytes including a null
		leay days,pcr		; setup pointer to day array
		leay a,y		; add on the offset from above
		jsr [copystr]		; append it to string in x

		leay timeoutput,pcr	; setup rtc data buffer again

		lda #ASC_SP		; space char
		sta ,x+			; add it so its after the day
		lda 4,y			; get date in month
		jsr [bytetoaschex]	; turn it into hex in x
		lda #'/			; '/'
		sta ,x+			; add the slash
		lda 5,y			; get the month
		jsr [bytetoaschex]	; turn it into hex in x
		lda #'/			; '/'
		sta ,x+			; add the slash
		lda 6,y			; get the year
		jsr [bytetoaschex]	; turn it into hex in x
		clr ,x+			; add the null

		leay outputbuffer,pcr	; reset output buffer

		jsr [putstrdefio]	; output the date ( DD/MM/YY)

		leay newlinez,pcr

		jsr [putstrdefio]	; and add a newline

		clra
		
		rts

; days array - each day is 4 bytes long

spiz:		.asciz "spi"

days:		.asciz 'Sun'
		.asciz 'Mon'
		.asciz 'Tue'
		.asciz 'Wed'
		.asciz 'Thu'
		.asciz 'Fri'
		.asciz 'Sat'

newlinez:	.asciz '\r\n'

outputbuffer:	.rmb 16			; the spi buffer
timeoutput:	.rmb 7			; string to hold formatted data
spidevice:	.rmb 2			; the open spi device

end:		.byte 0
