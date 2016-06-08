; inits a list in y

initlist:	pshs x			; save x, we'll need it later
		leax LIST_TAIL,y	; calc the tail node
		stx LIST_HEAD,y		; set the dummy head
		ldx #0			; null
		stx LIST_TAIL,y		; set the dummy tail
		leax LIST_HEAD,y	; calc the head node
		stx LIST_TAILPREV,y	; set the dummy tail prev
		puls x			; restore x
		rts

; adds node at x to list in y at head

addhead:	pshs u			; save u
		ldu LIST_HEAD,y		; get the current head
		stx NODE_PREV,u		; set old head node's prev to new node
		stu NODE_NEXT,x		; set the new next to current head
		sty NODE_PREV,x		; set the new prev to head
		stx LIST_HEAD,y		; set the new head to new node
		puls u			; restore u
		rts

; add node at x to list in y at tail

addtail:	pshs u			; save u
		ldu LIST_TAILPREV,y	; get the current tail
		stx NODE_NEXT,u		; set old tail node's next to new node
		stu NODE_PREV,x		; set the new prev to current tail
		leay LIST_TAIL,y	; move list to its tail
		sty NODE_NEXT,x		; set the new next to tail
		stx LIST_TAIL,y		; set the new tail to the new node
		puls u			; restore u
		rts

; remove the head from list in y, old head in x

remhead:	pshs u			; save u
		ldu LIST_HEAD,y		; get the current head
		ldx NODE_NEXT,u		; get that node's next
		beq 1$			; if empty, nothing to do
		stx LIST_HEAD,y		; make this the new head
		exg u,x
		sty NODE_PREV,u		; and make this nodes prev the head
1$:		puls u			; restore u
		rts

; remove the tail from list in y, old tail in x

remtail:	pshs u			; save u
		ldu LIST_TAILPREV,y	; get the current tail
		ldx NODE_PREV,u		; get that node's prev
		beq 1$			; if empty, nothing to do
		stx LIST_TAILPREV,y	; make this the new tail
		exg u,x
		leay 2,y		; move to the tail end of header
		sty NODE_NEXT,u		; and make this nodes next the tail
		leay -2,y		; need to restore the real header
1$:		puls u			; restore u
		rts

; remove a node in x

remove:		pshs u,y		; save u and y
		ldy NODE_NEXT,x		; get the dead nodes next
		ldu NODE_PREV,x		; get the dead nodes prev
		sty NODE_NEXT,u		; make the prevs next the prev
		stu NODE_PREV,y		; make the nexts prev the next
		puls u,y		; restore u and y
		rts

