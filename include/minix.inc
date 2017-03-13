; minix data structures, used by the driver and other routines

; fields are assumed to be 16 bit words unless otherwise noted

; magic

MINIX_MAGIC	.equ 0x138f

; superblock

MINIXSB_NINODES	.equ 0		; number of inodes
MINIXSB_NZONES	.equ 2		; number of zones
MINIXSB_IMAPBLK	.equ 4		; number of inode bitmap blocks
MINIXSB_ZMAPBLK	.equ 6		; number of zone bitmap blocks
MINIXSB_FIRSTDZ	.equ 8		; first data zone
MINIXSB_LZSIZE	.equ 10
MINIXSB_MAXSIZE	.equ 12		; maximum file size
MINIXSB_MAGIC	.equ 16		; magic!
MINIXSB_STATE	.equ 18		; clean/dirty state?
MINIXSB_ZONES	.equ 20		; number of zones? (long)
MINIXSB_SBSIZE	.equ 24		; the size on disk (not a struct field)
; below here is memory only, not on the disk
MINIXSB_DEVICE	.equ 24		; the underlying device
MINIXSB_INOFF	.equ 26		; the block number the inodes start at
MINIXSB_INBASE	.equ 28		; first inode div32 number in cache
MINIXSB_INCACHE	.equ 30 	; inodes currently available
MINIXSB_SIZE	.equ 30+1024	; the in-memory size

; inode

MINIXIN_MODE	.equ 0		; type (socket, file, directory) and perms
MINIXIN_UID	.equ 2		; user id
MINIXIN_LENGTH	.equ 4		; file size (long)
MINIXIN_TIME	.equ 8		; timestamp (long)
MINIXIN_GID	.equ 12		; group id (byte!)
MINIXIN_NLINKS	.equ 13		; number of links (byte)
MINIXIN_ZONES	.equ 14		; seven zone (block) pointers
MINIXIN_SIZE	.equ 14+(2*9)	; 32 bytes

; directory entry (dirent)

MINIXDE_INODE	.equ 0		; inode number
MINIXDE_NAME	.equ 2		; null padded filename
MINIXDE_SIZE	.equ 2+30	; 32 bytes
