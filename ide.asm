; ide low level driver

		.include 'system.inc'
		.include 'hardware.inc'

IDE_CUR_POS	.equ DEVICE_SIZE+0	; ide current position (sector)
IDE_SIZE	.equ DEVICE_SIZE+2

		.area RAM

ideinuse:	.rmb 1			; 1 for open, 0 for closed

		.area ROM

idedef::	.word ideopen
		.word 0x0000
		.asciz "ide"

; ide open

ideopen:	lbsr disable		; enter critical section
		lda ideinuse
		bne 1$			; in use?
		lda #1			; mark it as being in use
		sta ideinuse		; ...
		ldx #IDE_SIZE		; allocate the device struct
		lbsr memoryalloc	; get the memory for the struct
		ldy #ideclose		; save the close pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #ideread		; save the write pointer
		sty DEVICE_READ,x	; ... in the device struct
		ldy #idewrite
		sty DEVICE_WRITE,x	; read
		ldy #ideseek
		sty DEVICE_SEEK,x	; and seek
		ldy #idecontrol
		sty DEVICE_CONTROL,x	; control
		ldy #0			; reset ...
		sty IDE_CUR_POS,x	; ... current position

		lda #IDEFEATURE8BIT	; 8 bit enable
		sta IDEFEATURES
		lda #IDECOMFEATURES	; set features
		lbsr simpleidecomm
		lbsr idewaitnotbusy

		lbsr enable		; exit critical section
		setzero
		rts
1$:		lbsr enable		; exit critical section
		ldx #0			; return 0
		setnotzero		; port is in use
		rts

; ide close - give it the device in x

ideclose:	lbsr disable
		clr ideinuse		; mark it unused
		lbsr memoryfree		; free the open device handle
		lbsr enable
		setzero
		rts


; ideread - read 1 sector into y

ideread:	lbsr seekcurpos		; seek to the current position

		lda #IDECOMREADSEC	; this is read sector
		lbsr simpleidecomm	; send the command

		lbsr idellread		; read into y

		lbsr advancecurpos	; move on one sector

		setzero
		rts

; idewrite - write to the seeked sector

idewrite:	lbsr seekcurpos		; seek to the current position

		lda #IDECOMWRITESEC	; this is write sector
		lbsr simpleidecomm	; send the command

		lbsr idellwrite		; write into x

		lbsr advancecurpos	; move on one sector

		setzero
		rts

; sysctrl function - command in a, block in y

idecontrol:	cmpa #IDECMD_IDENTIFY	; identify command?
		beq ideidentify		; do the identify

		setnotzero		; error
		rts

; ideidentify - get info about the device into y


		lbsr simpleidecomm	; send it

		lbsr idellread		; 512 reads into y

		setzero			; no error
		rts

; ideseek - set the current sector number

ideseek:	sty IDE_CUR_POS,x	; set the current position

		setzero
		rts

; setlba - sets the lba registers up for the disk block at the current
; position

seekcurpos:	pshs a,b		; transfer lba block number from y

		ldd IDE_CUR_POS,x	; get current position

		stb IDELBA0		; this is the lowest byte in lba
		sta IDELBA1		; this is the 2nd lowestbyte in lba

		clr IDELBA2		; other two lba are zero
		clr IDELBA3

		lda #1			; we are reading or writing ...
		sta IDECOUNT		; ... one sector

		puls a,b

		rts

; move the current position on one sector

advancecurpos:	pshs a,b
		ldd IDE_CUR_POS,x
		addd #1
		std IDE_CUR_POS,x
		puls a,b

		rts

;;; IDE LOW LEVEL

; run the trivial command in 'a', assuming other params are setup

simpleidecomm:	ldb #0b11100000		; lba mode
		stb IDEHEADS
		sta IDECOMMAND
		rts

idewaitnotbusy:	lda IDESTATUS
		anda #IDESTATUSBSY
		bne idewaitnotbusy
		rts

idewaitfordata:	lda IDESTATUS
		anda #IDESTATUSDRQ
		beq idewaitfordata
		rts

; read 512 bytes from the ide and store it in y

idellread:	lbsr idewaitnotbusy
		lbsr idewaitfordata
		ldx #256
1$:		ldb IDEDATA
		lda IDEDATA
		std ,y++
		leax -1,x
		bne 1$
		rts

; write 512 bytes to the ide from y

idellwrite:	lbsr idewaitnotbusy
		ldx #256
1$:		ldd ,y++
		stb IDEDATA
		sta IDEDATA
		leax -1,x
		bne 1$
		rts
