; minix driver - sits atop the block (ide) driver

		.include '../../include/system.inc'
		.include '../../include/hardware.inc'
		.include '../../include/debug.inc'

MINIX_DEVICE	.equ DEVICE_SIZE	; underlying block device
MINIX_MOUNT	.equ DEVICE_SIZE+2	; the mounted volume struct
MINIX_SIZE	.equ DEVICE_SIZE+4

		.area ROM

minixdef::	.word minixopen
		.word 0x0000
		.asciz "minix"

minixopen::

; LOW LEVEL

; getblock - get the 1024 byte block in sector d, from the file device at
; x, into the memory at y

getfsblock:	pshs x			; save the file handle
		ldx MINIX_DEVICE,x	; get the block device
		lslb			; rotate low byte to left
		rola			; and rotate the high byte, multiply d by 2
		tfr d,u			; save the sector number
		lda #2			; 2 sectors per filesystem block
		lbsr sysread		; get the fs block into y
		puls x			; leave with the file handle in x
		rts

