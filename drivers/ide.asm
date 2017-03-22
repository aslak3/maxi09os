; ide low level driver

		.include '../include/system.inc'
		.include '../include/hardware.inc'

PARTS		.equ 4			; 4 disk partitions

; mbr sector offsets

MBR_PARTS_TABLE	.equ 0x01be		; start of parition entries in mbr
MBR_SIGNATURE	.equ 0x01fe		; 55 aa boot signature

; mbr partition table entry offsets

structstart	0
member		MBR_PART_STATUS,1	; offset into status/boot byte
member		MBR_CHS,7		; chs values, not used
member		MBR_PART_START,4	; long word lba offset
member		MBR_PART_LENGTH,4	; long word lba count
structend	MBR_PART_SIZE		; 16 bytes

; partition entry for this driver's parttable

structstart	0
member		PART_DEVICE,2		; device handle
member		PART_START,2		; lba offset
member		PART_LENGTH,2		; lba count
member		PART_FLAGS,1		; copy of status/boot byte
member		PART_DUMMY,1		; unused
structend	PART_SIZE		; 8 bytes

structstart	DEVICE_SIZE
member		IDE_SECT_COUNT,1	; number of sectors we are ioing
member		IDE_OPEN_COUNT,1	; number of times open this device
member		IDE_PART,2		; pointer to part structure
member		IDE_PART_START,2	; the offset into the partition
member		IDE_SECTOR,512		; a disk sector
structend	IDE_SIZE

		.area RAM

parttable:	.rmb PART_SIZE		; the whole disk partition
parttableone:	.rmb PART_SIZE*PARTS	; the actual partition

		.area ROM

idedef::	.word ideopen
		.word 0x0000
		.asciz "ide"

; ide open - a is the unit/partition number, 0 for the whole disk

ideopen:	pshs a,y,u
		lbsr forbid		; enter critical section
		ldy #parttable		; get the local partition table
		lsla			; x2
		lsla			; x2
		lsla			; x2 ... makes x8
		leau a,y		; get the partition entry from a
		ldx PART_DEVICE,u	; get the open device for this part
		bne 1$			; in use already? return it now

		ldx #IDE_SIZE		; allocate the device struct
		lbsr memoryalloc	; get the memory for the struct
		ldy #ideclose		; save the close sub pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #ideread		; save the read sub pointer
		sty DEVICE_READ,x	; ... in the device struct
		ldy #idewrite		; save the write sub pointer
		sty DEVICE_WRITE,x	; ... in the device struct
		ldy #devicenotimpl	; seek isn't implemented
		sty DEVICE_SEEK,x	; as ide head is stateless
		ldy #idecontrol		; save the control sub pointer
		sty DEVICE_CONTROL,x	; ... in the device struct
		ldy PART_START,u	; get partition offset
		sty IDE_PART_START,x	; save it in device

		lda #IDEFEATURE8BIT	; 8 bit enable
		sta IDEFEATURES		; save it in features register
		lda #IDECOMFEATURES	; set features
		lbsr simpleidecomm	; run the features command
		stx PART_DEVICE,u	; save pointer to device in part
		stu IDE_PART,x		; save pointer to part in device

1$:		inc IDE_OPEN_COUNT,x	; and incrmenet open counter
		lbsr permit		; exit critical section

		setzero			; success
		puls a,y,u
		rts

; ide close - give it the device in x - if open elsewhere it will not free
; the handle but will always decrement the inuse counter

ideclose:	pshs u
		lbsr forbid		; enter critical section
		dec IDE_OPEN_COUNT,x	; mark it unused
		bne 1$			; still open? don't free yet
		ldu IDE_PART,x		; get the parttable pointer
		lbsr memoryfree		; free the open device handle
		ldx #0	
		stx PART_DEVICE,u	; zero out the handle
1$:		lbsr permit		; leave critical section
		setzero
		puls u
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
		lbsr idellreadswap	; 512 reads into y, swapped

		setzero			; no error
		bra idecontrolout

; read the mbr. read from sector 0, and fill out the partition table

idereadmbr:	leay IDE_SECTOR,x	; get the start of the sector
		ldu #0			; sector 0
		lda #1			; only 1 sector in an mbr

		lbsr ideread		; read it in

		leay IDE_SECTOR,x	; rewind back to start of mbr

		leay MBR_PARTS_TABLE,y	; first partition
		lda #4			; four physical partitions
		ldx #parttableone	; this is the drive-wide stored	table

1$:		lbsr parsembrpart	; parse this entry advancing y and x
		deca			; one less to go
		bne 1$			; more?

		setzero			; no error
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
; and also sets the sector count from a

seeknewpos:	sta IDECOUNT		; how many sectors?
		sta IDE_SECT_COUNT,x	; save the sector count

		tfr u,d			; get current position
		addd IDE_PART_START,x	; offset partitiion start
		stb IDELBA0		; this is the lowest byte in lba
		sta IDELBA1		; this is the 2nd lowest byte in lba
		clr IDELBA2		; other two lba are zero
		clr IDELBA3

		rts

; run the command in a, setting lba mode, and loop until the disk reports
; the disk is no longer busy running the command

simpleidecomm:	ldb #0b11100000		; lba mode
		stb IDEHEADS		; set in heads register
		sta IDECOMMAND		; set the command in command reg
1$:		lda IDESTATUS		; poll loop
		anda #IDESTATUSBSY	; get the status and loop until ...
		bne 1$			; ... not busy
		rts

; loop until status says there is data

idewaitfordata:	lda IDESTATUS		; get the status byte
		anda #IDESTATUSDRQ	; is there data?
		beq idewaitfordata	; if not, go back and reading status
		rts

; read from all the wanted sectors from the disk

idellread:	pshs y			; save the start of memory
		lbsr idewaitfordata	; need to wait for data, as reading
1$:		lbsr idellreadsect	; read a single 512 byte sector
		dec IDE_SECT_COUNT,x	; decrement sectors remaining
		bne 1$			; more? go and get it
		puls y			; restore the start of memory
		rts

; read one sector into y - no need to byte swap as we are in 8 bit mode
; reads two bytes at a time for small speed up

idellreadsect:	pshs x			; save x because it;s the device
		ldx #256		; setup the number words per sector
1$:		lda IDEDATA		; get the high byte first
		ldb IDEDATA		; get the low byte second
		std ,y++		; write both bytes together
		leax -1,x		; dec word counter
		bne 1$			; go back for more?
		puls x			; pull out the device handle
		rts

; write to all the wanted sectors to the disk - no need to wait for data cos
; we have it ourselves

idellwrite:	pshs y			; save the start of memory
		lbsr idellwritesect	; write a single 512 byte sector
		dec IDE_SECT_COUNT,x	; dectrement sectors remaining
		bne idellwrite		; more? go and write it
		puls y			; restore the start of memory
		rts

; write a sector from y - no need to byte swap because we are in 8 bit
; mode. write two bytes at a time for a small speedup

idellwritesect:	pshs x			; save x because it's the device
		ldx #256		; setup the number words per sector
1$:		ldd ,y++		; read both bytes from memory
		sta IDEDATA		; save the high byte first
		stb IDEDATA		; save the low byte second
		leax -1,x		; dec word coounter
		bne 1$			; go back for more?
		puls x			; pull out the device handle
		rts

; read one sector into y - swapping bytes as identify (and possibly other)
; commands return little endian data even when in 8 bit mode

idellreadswap:	pshs x,y		; save x because it's the device
		ldx #256		; setup the number words per sector
1$:		ldb IDEDATA		; get the high byte first
		lda IDEDATA		; get the low byte second
		std ,y++		; write both bytes together
		leax -1,x		; dec word counter
		bne 1$			; go back for more?
		puls x,y		; pull out the device handle
		rts
