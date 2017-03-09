; ide low level driver

		.include '../include/system.inc'
		.include '../include/hardware.inc'

PARTS		.equ 5			; number of partitions

PART_DEVICE	.equ 0			; pointer to handle
PART_START	.equ 2
PART_LENGTH	.equ 4
PART_FLAGS	.equ 6
PART_DUMMY	.equ 7
PART_SIZE	.equ 8

IDE_CUR_POS	.equ DEVICE_SIZE+0	; ide current position (sector)
IDE_SECT_COUNT	.equ DEVICE_SIZE+2
IDE_OPEN_COUNT	.equ DEVICE_SIZE+3
IDE_PART	.equ DEVICE_SIZE+4	; pointer to oart
IDE_PART_START	.equ DEVICE_SIZE+6
IDE_SIZE	.equ DEVICE_SIZE+8

		.area RAM

parttable:	.rmb PART_SIZE*PARTS

		.area ROM

idedef::	.word ideopen
		.word 0x0000
		.asciz "ide"

; ide open

ideopen:	lbsr disable		; enter critical section
		ldy #parttable
		lsla
		lsla
		lsla
		leau a,y
		ldx PART_DEVICE,u
		bne 1$			; in use already? return it now
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
		ldy PART_START,u	; get partition offset
		sty IDE_PART_START	; save it in device

		lda #IDEFEATURE8BIT	; 8 bit enable
		sta IDEFEATURES
		lda #IDECOMFEATURES	; set features
		lbsr simpleidecomm
		stx PART_DEVICE,u	; save open handle
1$:		inc IDE_OPEN_COUNT,x	; and incrmenet open counter
		lbsr enable		; exit critical section
		setzero
		rts

; ide close - give it the device in x - if open elsewhere it will not free
; the handle but will always decrement the inuse counter

ideclose:	lbsr disable
		dec IDE_OPEN_COUNT,x	; mark it unused
		bne 1$			; still open? don't free yet
		lbsr memoryfree		; free the open device handle
		ldu IDE_PART,x
		ldx #0
		stx PART_DEVICE,u	; zero out the handle
1$:		lbsr enable
		setzero
		rts

; ideread - read 1 sector into y

ideread:	lbsr seekcurpos		; seek to the current position

		lda #IDECOMREADSEC	; this is read sector
		lbsr simpleidecomm	; send the command

		lbsr idellread		; read into y

		lbsr advancecurpos	; move on

		setzero
		rts

; idewrite - write to the seeked sector

idewrite:	lbsr seekcurpos		; seek to the current position

		lda #IDECOMWRITESEC	; this is write sector
		lbsr simpleidecomm	; send the command

		lbsr idellwrite		; write into x

		lbsr advancecurpos	; move on

		setzero
		rts

; sysctrl function - command in a, block in y

idecontrol:	cmpa #IDECMD_IDENTIFY	; identify command?
		beq ideidentify		; do the identify

		setnotzero		; error
		rts

; ideidentify - get info about the device into y

ideidentify:	lda #IDECOMIDENTIFY	; the identify command
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

seekcurpos:	sta IDECOUNT		; how many sectors?
		sta IDE_SECT_COUNT,x	; save the sector count

		ldd IDE_CUR_POS,x	; get current position
		addd IDE_PART_START,x	; offset partitiion start
		stb IDELBA0		; this is the lowest byte in lba
		sta IDELBA1		; this is the 2nd lowestbyte in lba
		clr IDELBA2		; other two lba are zero
		clr IDELBA3

		rts

; move the current position on one sector

advancecurpos:	lda IDELBA1		; get the new position
		ldb IDELBA0
		addd #1			; when done, need to move to next
		subd IDE_PART_START,x
		std IDE_CUR_POS,x	; save the new position

		rts

;;; IDE LOW LEVEL

; run the trivial command in 'a', assuming other params are setup

simpleidecomm:	ldb #0b11100000		; lba mode
		stb IDEHEADS
		sta IDECOMMAND
1$:		lda IDESTATUS
		anda #IDESTATUSBSY
		bne 1$
		rts

idewaitfordata:	lda IDESTATUS
		anda #IDESTATUSDRQ
		beq idewaitfordata
		rts

; read from the ide and store it in y

idellread:	lbsr idewaitfordata
1$:		lbsr idellreadsect
		dec IDE_SECT_COUNT,x
		bne 1$
		rts

; read one sector into y

idellreadsect:	pshs x
		ldx #256
1$:		lda IDEDATA
		ldb IDEDATA
		std ,y++
		leax -1,x
		bne 1$
		puls x
		rts

; write to the ide from y

idellwrite:	lbsr idellwrite
		dec IDE_SECT_COUNT,x
		bne idellwrite
		rts

; write a sector from y

idellwritesect:	ldx #256
1$:		ldd ,y++
		stb IDEDATA
		sta IDEDATA
		leax -1,x
		bne 1$
		rts
