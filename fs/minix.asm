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
		lbsr memoryalloc	; get the superblock memory
		tfr x,y			; it will be read into here
		tfr u,x			; get the device back
		lbsr readsuperblock	; read the superblock in y
		ldx #MINIXSB_SIZE	; the in memory superblock
		lbsr memoryalloc	; x is now the the superblock copy
		exg x,y			; y is now the copy, x is the source
		lda #MINIXSB_SIZE	; we copy this number of bytes
		lbsr memcpy256		; y is the copy of the superblock
		lbsr memoryfree		; free the disk superblock
		stu MINIXSB_DEVICE,y	; set the underlying disk device
1$:		puls x,u,a
		rts

; unmountminix - unmount the fs referenced by the superblock in y, the
; underlying device is not closed

unmountminix::	pshs x
		tfr y,x			; get the superblock memory block
		lbsr memoryfree		; free it
		puls x
		rts

; readsuperblock - read superblock for device x into y, which is restored
; on completion

readsuperblock:	pshs a,u
		lda #2			; 2 sectors in a block
		ldu #2			; superblock at block 1
		lbsr sysread		; read it in
		puls a,u
		rts
