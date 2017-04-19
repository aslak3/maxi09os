; minix driver - sits atop the block (prob ide) driver and presents read and
; writes to the contents of a "file", which might be a directory, symlink etc

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'
		.include 'include/minix.inc'

		.globl memoryalloc
		.globl memoryfree
		.globl currenttask
		.globl rootsuperblock
		.globl devicenotimpl
		.globl getinode
		.globl readfsblock
		.globl getbytes
		.globl swapword
		.globl swaplong
		.globl strcmp
		.globl memcpy256

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
		ldy #minixclose
		sty DEVICE_CLOSE,x	; close sub
		ldy #minixread
		sty DEVICE_READ,x	; read sub
		ldy #minixseek
		sty DEVICE_SEEK,x	; seek sub
		ldy #0
		sty MINIX_CURPOS,x	; reset current position
		lbsr readfileinode	; update the local inode
		clra			; read in the first block
		lbsr updatecurblock	; get the first block
		clra
		rts

; minix close - close the file in x

minixclose:	lbsr memoryfree		; free up the memory
		setzero			; always succeed
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
1$:		lbsr checkeof		; check for eof
		puls b,y
		rts

; checkeof - if at the end of the file, then set not zero. otherwise set
; zero

checkeof:	pshs a,b,x
		ldd MINIX_CURPOS,x	; get current position
		leax MINIX_INODE,x	; move to the inode
		cmpd MINIXIN_LENGTH+2,x	; compare against length (low word)
		beq 1$			; end of file if we move into length
		setzero			; not at eof, success
		bra 2$			; exit now
1$:		setnotzero		; at the end, so error
2$:		puls a,b,x
		rts

; seek to the offset y

minixseek:	sty MINIX_CURPOS,x	; save the new position
		lbsr checkcurblock	; see if we have to read a block
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

; UTILITY

; findinodeindir - find the inode for the file named in u, searching in the
; directory x, resultant inode number in d. uses 32 bytes of stack

findinodeindir:	pshs x,y
		leas -MINIXDE_SIZE,s	; take 32 bytes of stack
		ldy #0			; seek back to start of dirents
		lbsr minixseek		; do the seek
		tfr s,y			; this is the dirent buffer
1$:		lbsr getnextdirent	; get the next dirent
		tst MINIXDE_NAME,y	; check for zero in first byte
		beq 2$			; no more dirents?
		lbsr comparedirent	; compare		
		bne 1$			; back for more
		ldd MINIXDE_INODENO,y	; get the inode number
		setzero			; success
		bra 3$			; done now 
2$:		ldd #0			; null inode number
		setnotzero		; not sucessful
3$:		leas MINIXDE_SIZE,s	; give 32 bytes of stack back
		puls x,y
		rts

; move to the next dirent for directory in x, wirting it into y

getnextdirent::	pshs x,u
		ldu #MINIXDE_SIZE	; set the size of the dirent
		lbsr getbytes		; read it in
		leax MINIXDE_INODENO,y	; move x to the inode number
		lbsr swapword		; swap it
		puls x,u
		rts

; compare the dirent at y's filename with the filename in u

comparedirent:	pshs x,y
		tfr u,x			; the filename being sought
		leay MINIXDE_NAME,y	; the filename in the dirent
		lbsr strcmp		; do the comparison
		puls x,y
		rts

; open a file by name, x is the directory and u is the name, the file is
; returned in x so the caller must store the directory handle away

openfileindir:	pshs a,b,y,u
		lbsr findinodeindir	; get the inode for this filename
		bne 1$			; not successful
		tfr d,u			; todo: move this to d in minixopen
		ldy MINIX_SB,x		; get the superblock struct
		lbsr minixopen		; open the file
		setzero
		bra 2$			; out now
1$:		ldx #0			; return nothing
		setnotzero		; failure
2$:		puls a,b,y,u
		rts

; stats a file by name, x is the directory and u is the name, and y is
; is where to put the inode

statfileindir:	pshs a,b,x
		lbsr findinodeindir	; find this inode
		bne 1$			; couldn't find the named inode
		ldx MINIX_SB,x		; get the superblock
		lbsr getinode		; fill inode d into memory y
		setzero			; success
1$:		puls a,b,x
		rts

; open the current working directory for the current task, using the system
; mounted root fs, returning it in x

opencwd::	pshs y,u
		ldx currenttask		; get the current task
		ldu TASK_CWD_INODENO,x	; get the cwd inode number
		ldy rootsuperblock	; get the mounted superblock
		lbsr minixopen		; opened file will be in
		puls y,u
		rts

; find the inode number for the file named in u, returing it in d

findinode::	pshs x,y
		lbsr opencwd		; open the current directory
		tfr x,y			; save it so we can close it later
		lbsr findinodeindir	; stat for the file
		bne 1$			; getting the inode failed
		tfr y,x			; get the dir back in x
		lbsr minixclose		; now close it
		setzero			; success
		bra 2$			; out we go
1$:		tfr y,x			; get the dir back in x
		lbsr minixclose		; now close it
		setnotzero		; failure
2$:		puls x,y
		rts

; open the file in the current directory, the name is in u, the open file
; will be in x

openfile::	pshs a,y
		lbsr opencwd		; open the current directory
		tfr x,y			; save it so we can close it later
		lbsr openfileindir	; open the file in the current dir
		tfr cc,a		; save condition codes
		exg y,x			; we need to close the dir now
		lbsr minixclose		; close the dir
		tfr y,x			; get thie file back in x
		tfr a,cc		; restore condition codes
		puls a,y
		rts

; just a convience alias

closefile::	lbra minixclose		; this is a branch

; stat the file in the current directory, the name is in u, the memory
; in y

statfile::	pshs a,x
		lbsr opencwd		; open the current directory
		lbsr statfileindir	; stat the file in u
		tfr cc,a		; save condition codes
		lbsr minixclose		; close the current directory
		tfr a,cc		; restore condition codes
		puls a,x
		rts

; grab a copy of the open file's inode and copy it into y

statopenfile::	pshs x
		leax MINIX_INODE,x	; move source of copy to inode
		lda #MINIXIN_SIZE	; set the size of the copy
		lbsr memcpy256		; copy the inode into y
		puls x
		rts

; get the type of the open file and put it in a, it is masked to include
; only the file type

typeopenfile::	pshs x
		leax MINIX_INODE,x	; move to the inode
		lda MINIXIN_MODE,x	; get the type
		anda #MODE_TYPE_MASK	; mask off to include just type
		puls x
		rts

; change current directory to the named dir in u. uses 32+2 bytes of stack.

changecwd::	pshs a,x,y
		leas -MINIXIN_SIZE,s	; get 32+2 bytes of stack
		tfr s,y			; set up the stat buffer
		lbsr statfile		; find the inode
		bne 1$			; out if that failed
		lda MINIXIN_MODE,y	; get file type
		anda #MODE_TYPE_MASK	; mask out perms bits
		cmpa #MODE_DIR		; is it a directory?
		bne 1$			; not a dir? then exit with failure
		ldd MINIXIN_INODENO,y	; get inode number
		ldx currenttask		; get the current task
		std TASK_CWD_INODENO,x	; save the new current dir
		setzero			; set success
		bra 2$			; skip to cleanup
1$:		setnotzero		; set failure
2$:		leas MINIXIN_SIZE,s	; wind stack forward
		puls a,x,y
		rts
