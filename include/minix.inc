; minix data structures, used by the driver and other routines

; superblock

MINIXSB_NINODES	.equ 0
MINIXSB_NZONES	.equ 2
MINIXSB_IMAPBLK	.equ 4
MINIXSB_ZMAPBLK	.equ 6
MINIXSB_FIRSTDZ	.equ 8
MINIXSB_LZ_SIZE	.equ 10
MINIXSB_MAXSIZE	.equ 12
MINIXSB_MAGIC	.equ 16
MINIXSB_STATE	.equ 18
MINIXSB_ZONES	.equ 20
; below here is memory only, not on the disk
MINIXSB_DEVICE	.equ 24		; the underlying device
MINIXSB_SIZE	.equ 26

; inode

MINIXIN_MODE	.equ 0
MINIXIN_UID	.equ 2
MINIXIN_SIZE	.equ 4
MINIXIN_TIME	.equ 8
MINIXIN_GID	.equ 12
MINIXIN_NLINKS	.equ 13
MINIXIN_ZONE	.equ 14
MINIXIN_SIZE	.equ 14+(2*9)	; 32 bytes

; dirent

MINIXDE_INODE	.equ 0		; inode number
MINIXDE_NAME	.equ 2
MINIXDE_SIZE	.equ 2+30	; 32 bytes
