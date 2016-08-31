; memory allocator and deallocator

		.include 'system.inc'
		.include 'debug.inc'

		.area ROM

HEAP_START	.equ 0x4000
HEAP_LEN	.equ 0x2000

MEM_NEXT_O	.equ 0
MEM_LENGTH_O	.equ 2
MEM_FREE_O	.equ 4
MEM_SIZE	.equ 5

memoryinit::	ldy #HEAP_START		; only one block to setup
		ldx #0			; null for end of list
		stx MEM_NEXT_O,y	; set the next entry to null
		ldx #HEAP_LEN		; get the total size
		stx MEM_LENGTH_O,y	; save it
		lda #1			; this block is free
		sta MEM_FREE_O,y	; so set it 
		rts

; output all the memory blocks

;startmsg:	.asciz 'Start: '
;lengthmsg:	.asciz 'Length: '
;freemsg:	.asciz 'Free: '

;memorydebug:	ldy #HEAP_START

;dumploop:	ldx #startmsg
;		tfr y,d
;		lbsr putlabd

;		ldx #lengthmsg
;		ldd MEM_LENGTH_O,y
;		lbsr putlabd

;		ldx #freemsg
;		lda MEM_FREE_O,y
;		lbsr putlaba

;		ldx #newlinemsg
;		lbsr putstr

;		ldy MEM_NEXT_O,y	; get the next pointer
;		bne dumploop		; and go back to the top of the loop

;		clra
;		rts		

; memoryalloc - size of memory in x, start of allocated memory in x on
; return or 0

memoryallocmsg:	.asciz 'memoryalloc\r\n'

memoryalloc::	debug #memoryallocmsg
		debugx
		pshs a,b,y		; save y
		leax MEM_SIZE,x		; add the overhead to the request
		lbsr disable		; critical section
		ldy #HEAP_START		; start at the start of the heap
allocloop:	lda MEM_FREE_O,y	; get the free flag
		bne checkfree		; it's free, now check size
checknext:	ldy MEM_NEXT_O,y	; get the next pointer
		bne allocloop		; and go back to the top of the loop
		ldx #0			; ...if there is more, 
allocout:	lbsr enable		; end critical section
		puls a,b,y
		rts			; otherwise no more rams

checkfree:	cmpx MEM_LENGTH_O,y	; see how big this free block is
		ble blockfits		; it fits!
		bra checknext		; back to check the next one

blockfits:	pshs y			; we have our block
		clra			; this block now isn't free
		sta MEM_FREE_O,y	; save it
		ldu MEM_LENGTH_O,y	; get the size of the free block
		stx MEM_LENGTH_O,y	; and set the new nonfree block size
		tfr y,d			; d now has the start of the block
		addd MEM_LENGTH_O,y	; work out the start of the new free
		tfr d,x			; save the start of new free in x
		tfr u,d			; restore the orig free length in d
		subd MEM_LENGTH_O,y	; calc size of the new free block
		cmpd #MEM_SIZE		; enough to make a free block?
		ble blockfitso		; no extra free block needed
		ldu MEM_NEXT_O,y	; get the original next block
		stx MEM_NEXT_O,y	; link the nonfree block to the free
		tfr x,y			; y is now the new block
		std MEM_LENGTH_O,y	; save the free size
		lda #1			; mark it as free
		sta MEM_FREE_O,y	; ...
		stu MEM_NEXT_O,y	; link the new free block to next
blockfitso:	puls y			; return start of previously block
		leax MEM_SIZE,y		; add header offset, caller...
		bra allocout		; gets only the useable space
		
; free memory block at x

memoryfree::	lda #1			; we are freeing
		leax -MEM_SIZE,x	; go back the size of the struct
		sta MEM_FREE_O,x	; and set free to 1
		rts
