; minix data structures, used by the driver and other routines

; fields are assumed to be 16 bit words unless otherwise noted

; magic

MINIX_MAGIC	.equ 0x138f

; superblock

structstart	0
member 		MINIXSB_NINODES,2	; number of inodes
member 		MINIXSB_NZONES,2	; number of zones
member 		MINIXSB_IMAPBLK,2	; number of inode bitmap blocks
member 		MINIXSB_ZMAPBLK,2	; number of zone bitmap blocks
member 		MINIXSB_FIRSTDZ,2	; first data zone
member 		MINIXSB_LZSIZE,2
member 		MINIXSB_MAXSIZE,4	; maximum file size
member 		MINIXSB_MAGIC,2		; magic!
member 		MINIXSB_STATE,2		; clean/dirty state?
member 		MINIXSB_ZONES,4		; number of zones? (long)
structend 	MINIXSB_SBSIZE		; size on disk (not a struct field)
; below here is memory only, not on the disk
member 		MINIXSB_DEVICE,2	; the underlying device
member 		MINIXSB_INOFF,2		; block number the inodes start at
member 		MINIXSB_INBASE,2	; first inode div32 number in cache
member 		MINIXSB_INCACHE,1024 	; inodes currently available
structend	MINIXSB_SIZE		; the in-memory size

; inode

structstart	0
member		MINIXIN_MODE,2		; type: socket, file; perms
member		MINIXIN_UID,2		; user id
member		MINIXIN_LENGTH,4	; file size (long)
member		MINIXIN_TIME,4		; timestamp (long)
member		MINIXIN_GID,1		; group id (byte!)
member		MINIXIN_NLINKS,1	; number of links (byte)
member		MINIXIN_ZONES,9*2	; 9 zone (block) pointers
structend	MINIXIN_INSIZE		; size on disk (32 bytes)
; below here is memory, not on the disk
member		MINIXIN_INODENO,2	; the inode number
structend	MINIXIN_SIZE

; mode and perms

; file types
MODE_TYPE_MASK	.equ 0xf0		; for masking out the file types
MODE_SOCKET	.equ 0xc0		; unix socket
MODE_LINK	.equ 0xa0		; symbolic link
MODE_REGULAR	.equ 0x80		; regular file
MODE_BLOCK_DEV	.equ 0x60		; block device node
MODE_DIR	.equ 0x40		; directory
MODE_CHAR_DEV	.equ 0x20		; character device node
MODE_FIFO	.equ 0x10 		; named pipe

; special bits
MODE_SETUID	.equ 0004000		; set user id
MODE_SETGID	.equ 0002000		; set group id
MODE_STICKY	.equ 0001000		; sticky bit

; user
MODE_IRWXU	.equ 00700		; all user perm set
MODE_IRUSR	.equ 00400		; user read
MODE_IWUSR	.equ 00200		; user write
MODE_IXUSR	.equ 00100		; user execute

; group
MODE_IRWXG	.equ 00070		; all group perm set
MODE_IRGRP	.equ 00040		; group read
MODE_IWGRP	.equ 00020		; group write
MODE_IXGRP	.equ 00010		; group execute

; other
MODE_IRWXO	.equ 00007		; all other perm set
MODE_IROTH	.equ 00004		; other read
MODE_IWOTH	.equ 00002		; other write
MODE_IXOTH	.equ 00001		; other execute

; directory entry (dirent)

structstart 	0
member		MINIXDE_INODENO,2			; inode number
member		MINIXDE_NAME,30			; null padded filename
structend	MINIXDE_SIZE			; 32 bytes
