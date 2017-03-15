 ; minix driver - sits atop the block (ide) driver

		.include '../../include/system.inc'
		.include '../../include/hardware.inc'
		.include '../../include/debug.inc'
		.include '../../include/minix.inc'

structrunning=DEVICE_SIZE
member		MINIX_SB,2		; A handle to the superblock 
member		MINIX_INODE_NO,2	; The inode number
member		MINIX_INODE,MINIXIN_SIZE; The current open file's inode
member		MINIX_BLOCK,1024	; The last read in fs block
structend	MINIX_SIZE

		.area ROM

minixdef::	.word minixopen
		.word 0x0000
		.asciz "minix"

; open a file by inode number - x is "minix", y is the minix superblock
; handle, and u is the inode number

minixopen::

; LOW LEVEL

