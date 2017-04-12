; non-driver minix routines

		.include '../include/system.inc'
		.include '../include/hardware.inc'
		.include '../include/minix.inc'
		.include '../include/debug.inc'

		.area ROM

; mountminix - mount the device in x as minix, returning the superblock in y,
; which can be passed back to sysopen when opening a file

mountminix::	pshs x,u,a
		tfr x,u			; save the io device we are mounting
		ldx #2*IDESECTORSIZE	; we need two sectors worth
		lbsr memoryalloc	; get the disk superblock memory
		tfr x,y			; it will be read into here
		ldx #MINIXSB_SIZE	; the in memory superblock
		lbsr memoryalloc	; x is now the the superblock copy
		stu MINIXSB_DEVICE,x	; set the underlying disk device
		ldd #1			; superblock is block 1
		lbsr readfsblock	; read the superblock in y
		exg x,y			; y is now the copy, x is the source
		lda #MINIXSB_SBSIZE	; we copy this on dixk size
		lbsr memcpy256		; y is the copy of the superblock
		lbsr memoryfree		; free the disk superblock
		leax MINIXSB_NINODES,y	; swap number of inodes
		lbsr swapword
		leax MINIXSB_NZONES,y	; swap numnber of zones
		lbsr swapword
		leax MINIXSB_IMAPBLK,y	; swap number inode bitmap blocks
		lbsr swapword
		leax MINIXSB_ZMAPBLK,y	; swap number of zone bitmap blocks
		lbsr swapword
		leax MINIXSB_FIRSTDZ,y	; swap first data zone
		lbsr swapword
		leax MINIXSB_LZSIZE,y	; swap this too
		lbsr swapword
		leax MINIXSB_MAXSIZE,y	; swap the max file size
		lbsr swaplong		; long swap
		leax MINIXSB_MAGIC,y	; swap magic!
		lbsr swapword
		ldd #1+1		; boot block, plus superblock
		addd MINIXSB_IMAPBLK,y	; add inode map block length
		addd MINIXSB_ZMAPBLK,y	; add zone map block length
		std MINIXSB_INOFF,y	; save inode offset
		ldd MINIXSB_MAGIC,y	; load the magic back
		cmpd #MINIX_MAGIC	; check the magic
		bne 1$			; bad magic? clean up and exit
		ldd #0			; read the first inode block
		tfr y,x			; get the superblock back in x
		lbsr redoinodecache	; into the cache
		setzero			; sucess
		puls x,u,a
		rts
1$:		tfr y,x			; otherwise we need to ...
		lbsr memoryfree		; free it
		ldy #0			; and return zero
		setnotzero		; error
		puls x,u,a
		rts

; unmountminix - unmount the fs referenced by the superblock in y, the
; underlying device is not closed

unmountminix::	pshs x
		tfr y,x			; get the superblock memory block
		lbsr memoryfree		; free it
		puls x
		rts

; readfsblock - read the 1024 byte block in block d, from the mounted fs at
; x, into the memory at y

readfsblock::	pshs a,b,x,u		; save the file handle
		ldx MINIXSB_DEVICE,x	; get the block device
		lslb			; rotate low byte to left
		rola			; rotate high byte, multiply d by 2
		tfr d,u			; save the sector number
		lda #2			; 2 sectors per filesystem block
		lbsr sysread		; get the fs block into y
		puls a,b,x,u		; leave with the file handle in x
		rts

; getinode - get the inode d from the superblock fs in x, writing it into y
; consult the "cache" as we go - if it's in the block of inodes we already
; have then use that copy

getinode::	pshs a,b,x
		std MINIXIN_INODENO,y	; save the inode number
		subd #1			; inodes start at 1
		tfr d,u			; save inode number
		lbsr div32		; find the inode block
		lbsr forbid		; enter criticial section
		cmpd MINIXSB_INBASE,x	; compare it with the cache base
		bne 3$			; not got this inode
1$:		tfr u,d			; get inode back
		clra			; clear high byte
		andb #0b00011111	; mask off the inode position in block
		lbsr mul32		; d now has byte offset start of inode
		leax MINIXSB_INCACHE,x	; move x to the start of the cache
		leax d,x		; add on the 32 byte inode offset
		lda #MINIXIN_INSIZE	; copy the whole disk inode
		lbsr memcpy256		; and do the copy
		leax MINIXIN_MODE,y	; swap the file mode/type
		lbsr swapword
		leax MINIXIN_UID,y	; swap the uid
		lbsr swapword
		leax MINIXIN_LENGTH,y	; swap the filesize
		lbsr swaplong
		leax MINIXIN_TIME,y	; swap the timestamp
		lbsr swaplong
		leax MINIXIN_ZONES,y	; get the first zone (block)
		lda #9
2$:		lbsr swapword		; swap the zone (block) pointer
		leax 2,x		; advance to next zone
		deca			; next zone (block)
		bne 2$			; more zones?
		lbsr permit		; leave criticial section
		puls a,b,x
		rts
3$:		lbsr redoinodecache	; read the inode block
		bra 1$

; read in the inodes from inode block (inode div32) in d and update the cache

redoinodecache:	pshs y
		std MINIXSB_INBASE,x	; now save the new base
		addd MINIXSB_INOFF,x	; add the inode block offset
		leay MINIXSB_INCACHE,x	; read to the 32 element inode cache
		lbsr readfsblock	; do the actual block read
		puls y
		rts
