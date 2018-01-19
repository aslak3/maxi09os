; memory allocator and deallocator

		.include 'include/system.inc'
		.include 'include/hardware.inc'
		.include 'include/debug.inc'

		.globl forbid
		.globl permit

		.globl l_RAM

		.area ROM

; memoryavail - returns the total memory available, total amount free, or
; largest single free block, based on the flag in a (MEM_TOTAL, MEM_FREE
; or MEM_LARGEST) - result is in d

memoryavail::	debugreg ^'Memory avail: ',DEBUG_MEMORY,DEBUG_REG_A
		pshs y
		clrb			; memory size counter top half
		ldy #l_RAM		; start at the start of the heap
		lbsr forbid		; enter critical section
		cmpa #AVAIL_TOTAL	; total mode?
		beq dototal		; run the total loop
		cmpa #AVAIL_FREE	; free mode?
		beq dofree		; run the free loop
		cmpa #AVAIL_LARGEST	; largest mode
		beq dolargest		; run the largest loop
		clra			; invalid input, clear bottom
availout:	lbsr permit		; leave critical section
		puls y
		rts

dototal:	clra			; now clear bottom half
totalloop:	addd MEM_LENGTH,y	; add size up
		ldy MEM_NEXT,y		; get the next pointer
		bne totalloop		; and go back to the top of the loop
		bra availout

dofree:		clra			; now clear bottom half
freeloop:	tst MEM_FREE,y		; get the free flag
		beq freenext		; not free, skip
		addd MEM_LENGTH,y	; add size up
freenext:	ldy MEM_NEXT,y		; get the next pointer
		bne freeloop		; and go back to the top of the loop
		bra availout

dolargest:	clra			; now clear bottom half
largestloop:	tst MEM_FREE,y		; get the free flag
		beq largestnext		; not free, skip
		cmpd MEM_LENGTH,y	; compare x with this block len
		bgt largestnext		; not bigger? then enxt one
		ldd MEM_LENGTH,y	; otherwise copy the block size
largestnext:	ldy MEM_NEXT,y		; get the next pointer
		bne largestloop		; and go back to the top of the loop
		bra availout

; memoryalloc - size of memory in x, start of allocated memory in x on
; return or 0

memoryalloc::	debugreg ^'Memory alloc, bytes: ',DEBUG_MEMORY,DEBUG_REG_X
		pshs a,b,y,u		; save y
		leax MEM_SIZE,x		; add the overhead to the request
		lbsr forbid		; critical section
		ldy #l_RAM		; start at the start of the heap
allocloop:	tst MEM_FREE,y		; get the free flag
		bne checkfree		; it's free, now check size
checknext:	ldy MEM_NEXT,y		; get the next pointer
		bne allocloop		; and go back to the top of the loop
		ldx #0			; ...if there is more, 
allocout:	lbsr permit		; end critical section
		puls a,b,y,u
		debugreg ^'Got block: ',DEBUG_MEMORY,DEBUG_REG_X
		rts			; otherwise no more rams

checkfree:	cmpx MEM_LENGTH,y	; see how big this free block is
		ble blockfits		; it fits!
		bra checknext		; back to check the next one

blockfits:	clra			; this block now isn't free
		sta MEM_FREE,y		; save it
		ldu MEM_LENGTH,y	; get the size of the free block
		stx MEM_LENGTH,y	; and set the new nonfree block size
		tfr y,d			; d now has the start of the block
		addd MEM_LENGTH,y	; work out the start of the new free
		tfr d,x			; save the start of new free in x
		tfr u,d			; restore the orig free length in d
		subd MEM_LENGTH,y	; calc size of the new free block
		cmpd #MEM_SIZE		; enough to make a free block?
		ble blockfitso		; no extra free block needed
		ldu MEM_NEXT,y		; get the original next block
		stx MEM_NEXT,y		; link the nonfree block to the free
		exg x,y			; y is now the new, free, block
		std MEM_LENGTH,y	; save the free size
		lda #1			; mark it as free
		sta MEM_FREE,y		; ...
		stu MEM_NEXT,y		; link the new free block to next
		tfr x,y			; restore the allocated  block in y
blockfitso:	leax MEM_SIZE,y		; add header offset, caller...
		bra allocout		; gets only the useable space
		
; free memory block at x - don't stack x since the caller should not be
; using it after the call!

memoryfree::	debugreg ^'Memory freeing block: ',DEBUG_MEMORY,DEBUG_REG_X
		pshs a
		leax -MEM_SIZE,x	; go back the size of the struct
		lda #1			; we are freeing
		sta MEM_FREE,x		; and set free to 1
		puls a
		rts

; INTERNAL

; the heap is init to span the whole of ram, starting wit the end of the
; system variables. this space includes the temporary stack used in main
; to get the system runing.

_memoryinit::	debug ^'Memory init',DEBUG_MEMORY
		pshs a,b,x,y
		ldy #l_RAM		; only one block to setup
		ldx #0			; null for end of list
		stx MEM_NEXT,y		; set the next entry to null
		ldd #RAMEND		; get the total size
		subd #l_RAM		; subtract space used for vars
		std MEM_LENGTH,y	; save it
		lda #1			; this block is free
		sta MEM_FREE,y		; so set it 
		puls a,b,x,y
		rts

