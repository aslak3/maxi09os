; ide low level driver

		.include '../include/system.inc'
		.include '../include/hardware.inc'

PARTS		.equ 5			; number of partitions

MBR_PARTS_START	.equ 0x01be		; start of parition entries in mbr

MBR_PART_STATUS	.equ 0			; offset into status byte
MBR_PART_START	.equ 8
MBR_PART_LENGTH	.equ 12
MBR_PART_SIZE	.equ 16

PART_DEVICE	.equ 0			; device handle
PART_START	.equ 2
PART_LENGTH	.equ 4
PART_FLAGS	.equ 6
PART_DUMMY	.equ 7
PART_SIZE	.equ 8

IDE_SECT_COUNT	.equ DEVICE_SIZE+0	; number of sectors we are ioing
IDE_OPEN_COUNT	.equ DEVICE_SIZE+1	; number of times open this device
IDE_PART	.equ DEVICE_SIZE+2	; pointer to part 
IDE_PART_START	.equ DEVICE_SIZE+4	; the offset into the partition
IDE_SECTOR	.equ DEVICE_SIZE+6	; a disk sector
IDE_SIZE	.equ DEVICE_SIZE+6+512

		.area RAM

parttable::	.rmb PART_SIZE
parttableone:	.rmb PART_SIZE*(PARTS-1)

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
		ldy #devicenotimpl
		sty DEVICE_SEEK,x
		ldy #idecontrol
		sty DEVICE_CONTROL,x	; control
		ldy PART_START,u	; get partition offset
		sty IDE_PART_START,x	; save it in device

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

; ideread - read to memory y from sectors in u, count in a sectors

ideread:	lbsr seeknewpos		; seek to the current position

		lda #IDECOMREADSEC	; this is read sector
		lbsr simpleidecomm	; send the command

		lbsr idellread		; read into y

		setzero
		rts

; idewrite - write from memory y to sectors in u, count in a sectors

idewrite:	lbsr seeknewpos		; seek to the current position

		lda #IDECOMWRITESEC	; this is write sector
		lbsr simpleidecomm	; send the command

		lbsr idellwrite		; write into x

		setzero
		rts

; sysctrl function - command in a, block in y

idecontrol:	pshs x,y
		cmpa #IDECMD_IDENTIFY	; identify command?
		beq ideidentify		; do the identify
		cmpa #IDECMD_READ_MBR	; read mbr command
		beq idereadmbr		; do the read mbr

		setnotzero		; error
idecontrolout:	puls x,y
		rts

; ideidentify - get info about the device into y

ideidentify:	lda #IDECOMIDENTIFY	; the identify command
		lbsr simpleidecomm	; send it

		lda #1			; read 1 sector for identity block
		sta IDE_SECT_COUNT,x	; save the sector count
		lbsr idellread		; 512 reads into y

		setzero			; no error
		bra idecontrolout

; read the mbr. read from sector 0, and fill out the partition table

idereadmbr:	leay IDE_SECTOR,x	; get the start of the sector
		ldu #0			; sector 0
		lda #1			; only 1 sector in an mbr

		lbsr ideread		; read it in

		leay IDE_SECTOR,x	; rewind back to start of mbr

		leay MBR_PARTS_START,y	; first partition
		lda #4			; four physical partitions
		ldx #parttableone	; this is the drive-wide stored	table

1$:		lbsr parsembrpart	; parse this entry advancing y and x
		deca			; one less to go
		bne 1$			; more?

		setzero
		bra idecontrolout

parsembrpart:	pshs a,b

		lda MBR_PART_STATUS,y	; bootable etc
		sta PART_FLAGS,x	; save the flags

		ldd MBR_PART_START,y	; lowest word first
		exg a,b			; byte swap to big endian
		std PART_START,x	; save the starting offset

		ldd MBR_PART_LENGTH,y	; lowest word first
		exg a,b			; byte swap to big endian
		std PART_LENGTH,x	; save the starting offset

		leay MBR_PART_SIZE,y	; move along mbr sector
		leax PART_SIZE,x	; move to next partition

		puls a,b
		rts

;;; IDE LOW LEVEL

; seeknewpos - sets the lba registers up for the disk block at the sector u

seeknewpos:	sta IDECOUNT		; how many sectors?
		sta IDE_SECT_COUNT,x	; save the sector count

		tfr u,d			; get current position
		addd IDE_PART_START,x	; offset partitiion start
		stb IDELBA0		; this is the lowest byte in lba
		sta IDELBA1		; this is the 2nd lowestbyte in lba
		clr IDELBA2		; other two lba are zero
		clr IDELBA3

		rts

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
