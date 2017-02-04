; memory allocator and deallocator

		.include 'system.inc'
		.include 'hardware.inc'
		.include 'debug.inc'

.globl		l_RAM

		.area ROM

MEM_NEXT_O	.equ 0
MEM_LENGTH_O	.equ 2
MEM_FREE_O	.equ 4
MEM_SIZE	.equ 5

memoryinit::	debug ^'Memory init',DEBUG_MEMORY
		pshs a,b,x,y
		ldy #l_RAM		; only one block to setup
		ldx #0			; null for end of list
		stx MEM_NEXT_O,y	; set the next entry to null
		ldd #RAMEND		; get the total size
		subd #l_RAM
		std MEM_LENGTH_O,y	; save it
		lda #1			; this block is free
		sta MEM_FREE_O,y	; so set it 
		puls a,b,x,y
		rts

; memoryavail - returns the total memory available, total amount free, or
; largest single free block, based on the flag in a (MEM_TOTAL, MEM_FREE
; or MEM_LARGEST) - result is in d

memoryavail::	debugreg ^'Memory avail: ',DEBUG_MEMORY,DEBUG_REG_A
		pshs y
		clrb			; memory size counter top half
		ldy #l_RAM		; start at the start of the heap
		lbsr disable		; enter critical section
		cmpa #MEM_TOTAL		; total mode?
		beq dototal		; run the total loop
		cmpa #MEM_FREE		; free mode?
		beq dofree		; run the free loop
		cmpa #MEM_LARGEST	; largest mode
		beq dolargest		; run the largest loop
		clra			; invalid input, clear bottom

availout:	lbsr enable		; leave critical section
		puls y
		rts

dototal:	clra			; now clear bottom half
totalloop:	addd MEM_LENGTH_O,y	; add size up
		ldy MEM_NEXT_O,y	; get the next pointer
		bne totalloop		; and go back to the top of the loop
		bra availout

dofree:		clra			; now clear bottom half
freeloop:	tst MEM_FREE_O,y	; get the free flag
		beq freenext		; not free, skip
		addd MEM_LENGTH_O,y	; add size up
freenext:	ldy MEM_NEXT_O,y	; get the next pointer
		bne freeloop		; and go back to the top of the loop
		bra availout

dolargest:	clra			; now clear bottom half
largestloop:	tst MEM_FREE_O,y	; get the free flag
		beq largestnext		; not free, skip
		cmpd MEM_LENGTH_O,y	; compare x with this block len
		bgt largestnext		; not bigger? then enxt one
		ldd MEM_LENGTH_O,y	; otherwise copy the block size
largestnext:	ldy MEM_NEXT_O,y	; get the next pointer
		bne largestloop		; and go back to the top of the loop
		bra availout

; memoryalloc - size of memory in x, start of allocated memory in x on
; return or 0

memoryalloc::	debugreg ^'Memory alloc, bytes: ',DEBUG_MEMORY,DEBUG_REG_X
		pshs a,b,y,u		; save y
		leax MEM_SIZE,x		; add the overhead to the request
		lbsr disable		; critical section
		ldy #l_RAM		; start at the start of the heap
allocloop:	tst MEM_FREE_O,y	; get the free flag
		bne checkfree		; it's free, now check size
checknext:	ldy MEM_NEXT_O,y	; get the next pointer
		bne allocloop		; and go back to the top of the loop
		ldx #0			; ...if there is more, 
allocout:	lbsr enable		; end critical section
		puls a,b,y,u
		debugreg ^'Got block: ',DEBUG_MEMORY,DEBUG_REG_X
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

memoryfree::	debugreg ^'Memory freeing block: ',DEBUG_MEMORY,DEBUG_REG_X
		pshs a,x
		lda #1			; we are freeing
		leax -MEM_SIZE,x	; go back the size of the struct
		sta MEM_FREE_O,x	; and set free to 1
		puls a,x
		rts
