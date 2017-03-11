; ide low level driver

		.include '../include/system.inc'
		.include '../include/hardware.inc'

PARTS		.equ 4			; 4 disk partitions

; mbr sector offsets

MBR_PARTS_TABLE	.equ 0x01be		; start of parition entries in mbr
MBR_SIGNATURE	.equ 0x1fe		; 55 aa boot signature

; mbr partition table entry offsets

MBR_PART_STATUS	.equ 0			; offset into status/boot byte
MBR_PART_START	.equ 8			; long word lba offset
MBR_PART_LENGTH	.equ 12			; long word lba count
MBR_PART_SIZE	.equ 16

; partition entry for this driver's parttable

PART_DEVICE	.equ 0			; device handle
PART_START	.equ 2			; lba offset
PART_LENGTH	.equ 4			; lba count
PART_FLAGS	.equ 6			; copy of status/boot byte
PART_DUMMY	.equ 7			; unused
PART_SIZE	.equ 8

IDE_SECT_COUNT	.equ DEVICE_SIZE+0	; number of sectors we are ioing
IDE_OPEN_COUNT	.equ DEVICE_SIZE+1	; number of times open this device
IDE_PART	.equ DEVICE_SIZE+2	; pointer to part structure
IDE_PART_START	.equ DEVICE_SIZE+4	; the offset into the partition
IDE_SECTOR	.equ DEVICE_SIZE+6	; a disk sector
IDE_SIZE	.equ DEVICE_SIZE+6+512

		.area RAM

parttable::	.rmb PART_SIZE		; the whole disk partition
parttableone:	.rmb PART_SIZE*PARTS	; the actual partition

		.area ROM

idedef::	.word ideopen
		.word 0x0000
		.asciz "ide"

; ide open - a is the unit/partition number, 0 for the whole disk

ideopen:	lbsr disable		; enter critical section
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
		stx PART_DEVICE,u	; save open handle

1$:		inc IDE_OPEN_COUNT,x	; and incrmenet open counter
		lbsr enable		; exit critical section

		setzero			; success
		rts

; ide close - give it the device in x - if open elsewhere it will not free
; the handle but will always decrement the inuse counter

ideclose:	lbsr disable		; enter critical section
		dec IDE_OPEN_COUNT,x	; mark it unused
		bne 1$			; still open? don't free yet
		lbsr memoryfree		; free the open device handle
		ldu IDE_PART,x		; get the parttable pointer
		ldx #0	
		stx PART_DEVICE,u	; zero out the handle
1$:		lbsr enable		; leave critical section
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

idellread:	lbsr idewaitfordata	; need to wait for data, as reading
1$:		lbsr idellreadsect	; read a single 512 byte sector
		dec IDE_SECT_COUNT,x	; decrement sectors remaining
		bne 1$			; more? go and get it
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

idellwrite:	lbsr idellwritesect	; write a single 512 byte sector
		dec IDE_SECT_COUNT,x	; dectrement sectors remaining
		bne idellwrite		; more? go and write it
		rts

; write a sector from y - no need to byte swap because we are in 8 bit
; mode. write two bytes at a time for a small speedup

idellwritesect:	pshs x			; save x because it's the device
		ldx #256		; setup the number words per sector
1$:		ldd ,y++		; read both bytes from memory
		stb IDEDATA		; save the low byte first
		sta IDEDATA		; save the high byte second
		leax -1,x		; dec word coounter
		bne 1$			; go back for more?
		puls x			; pull out the device handle
		rts
