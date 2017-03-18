; minix driver - sits atop the block (prob ide) driver and presents read and
; writes to the contents of a "file", which might be a directory, symlink etc

		.include '../../include/system.inc'
		.include '../../include/hardware.inc'
		.include '../../include/debug.inc'
		.include '../../include/minix.inc'

structstart	DEVICE_SIZE
member		MINIX_SB,2		; a handle to the superblock 
member		MINIX_INODENO,2		; the inode number
member		MINIX_INODE,MINIXIN_SIZE; the current open file's inode
member		MINIX_CURPOS,2		; current position
member		MINIX_ZONEINDEX,1	; the offset for this block
member		MINIX_BLOCK,1024	; the last read in fs block
structend	MINIX_SIZE

		.area ROM

minixdef::	.word minixopen
		.word 0x0000
		.asciz "minix"

; open a file by inode number - y is the minix superblock handle, and u is
; the inode number

minixopen:	ldx #MINIX_SIZE		; the size of the struct we need
		lbsr memoryalloc	; get it, into x
		sty MINIX_SB,x		; save the superblock pointer
		stu MINIX_INODENO,x	; save the inode number into file
		ldy #minixread
		sty DEVICE_READ,x	; read sub
		ldy #0
		sty MINIX_CURPOS,x	; reset current position
		lbsr readfileinode	; update the local inode
		clra			; read in the first block
		lbsr updatecurblock	; get the first block
		clra
		rts

; minixread - return the next byte from the file, at entry the in memory
; block is up to date

minixread:	pshs b,y
		ldd MINIX_CURPOS,x	; get the current block
		anda #0b00000011	; mask out the >1024 position
		leay MINIX_BLOCK,x	; get the disk block
		lda d,y			; get the byte
		inc MINIX_CURPOS+1,x	; increment low byte pos
		bne 1$			; no 256 wrap, so done now
		inc MINIX_CURPOS,x	; increment high byte
		lbsr checkcurblock	; maybe we have to get a new block?
1$:		setzero
		puls b,y
		rts

; LOW LEVEL

; read the disk inode into the file struct - x is the file struct

readfileinode:	pshs d,x,y
		leay MINIX_INODE,x	; calculate the memory block
		ldd MINIX_INODENO,x	; get the inode number into d
		ldx MINIX_SB,x		; get the superblock pointer
		lbsr getinode		; update the in-memory inode
		puls d,x,y
		rts

; check if we have to update the current block

checkcurblock:	pshs a
		lda MINIX_CURPOS,x	; div256 the current pos
		lsra			; div512
		lsra			; div1024
		cmpa MINIX_ZONEINDEX,x	; see if we are on the same block
		beq 1$			; nothing to do
		lbsr updatecurblock
1$:		puls a
		rts

; update the in memory block by reading in the a'th zone in the file

updatecurblock:	pshs a,b,x,y
		sta MINIX_ZONEINDEX,x	; save zone offset for next time
		leay MINIX_INODE,x	; get the inode buffer
		leay MINIXIN_ZONES,y	; the zone list
		lsla			; 2 bytes per word
		ldd a,y			; get the block number for this pos
		leay MINIX_BLOCK,x	; calc the block position
		ldx MINIX_SB,x		; get superblock handle
		lbsr readfsblock	; do the actual block read
		puls a,b,x,y
		rts
