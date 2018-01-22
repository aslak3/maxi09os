; Main snake source

		.include '../include/subtable.inc'

		.include '../../include/ascii.inc'
		.include '../../include/hardware.inc'
		.include '../../include/v99lowlevel.inc'

		.include 'snake.inc'

		.globl clearscreen
		.globl drawplayarea
		.globl clearplayarea
		.globl printstrat
		.globl readjoystick
		.globl stampat
		.globl peekat
		.globl drawbox

		.globl stamp
		.globl peek

; This is a whole game

gameovermsg:	.asciz 'Game Over...'

game::		lbsr randominit		; prepare the pseudo random numbers

		lda #3			; start with 3 lives
		sta lives,pcr		; save the lives

		ldx #0x2000		; starting delay
		stx movementdelay,pcr	; it's reduced as snake grows

		lda #2			; start at length of two
		sta snakelength,pcr	; save the length
		clr headpos,pcr		; snake snarts at the top of table

		lbsr clearscreen	; clear scren at te start
		lbsr drawplayarea	; draw the border

lifeloop:	lbsr clearplayarea	; clear the main portion
		lbsr showlives		; show the number of lives

		lda #12			; row coord of where snake starts
		leax rowsnake,pcr	; get the top of the row table
		clrb			; counter
rowinitloop:	sta ,x+			; save the same row along the table
		decb			; 256 bytess
		bne rowinitloop		; back for more

		lda #16			; col coord of whee snake starts
		leax colsnake,pcr	; get the top of the col table
		clrb			; counter
colinitloop:	sta ,x+			; save the smae col along the table
		decb			; 256 bytes
		bne colinitloop		; back for more

		clr rowdirection,pcr	; snake moves...
		lda #1			; across to the right...
		sta coldirection,pcr	; but not along at the start

		lbsr placenewfood	; place the first food on the map

		; main loop of the game

mainloop:	clra			; we are blanking out the far end
		ldb headpos,pcr		; get the current end index
		subb snakelength,pcr	; subtract the length (may wrap)
		lbsr drawsnakepart	; and rubout the far end of the snake

		lda #SNAKEBODYTILE	; draw over the last head tile
		ldb headpos,pcr		; with a body tile
		lbsr drawsnakepart	; snake is now headless :(

		lbsr movesnake		; move snake, inrementing headpos

		ldb headpos,pcr		; load the new headpos
		lbsr testcollide	; and see if theres been a collision
		beq nocollision		; if not, skip

		lbsr docollision	; process the collision
		beq death		; if it set zero, then snake is dead

nocollision:	lda #SNAKEHEADTILE	; finally we can draw the new head
		ldb headpos,pcr		; get the headposition again
		lbsr drawsnakepart	; and draw the head

		ldx movementdelay,pcr	; delay the game
controlloop:	lbsr controlsnake	; but in each delay loop, poll stick
		leax -1,x		; decrement delay
		bne controlloop		; until zero

		bra mainloop		; and back to the top again

death:		dec lives,pcr		; down a life!
		bne lifeloop		; start of life,  center snake

		lbsr showlives		; show that all lives are gone

		lda #12			; center the game over message
		ldb #10			; ...
		leax gameovermsg,pcr	; ...
		lbsr printstrat		; ...

gameoverloop:	lbsr readjoystick	; read the joystick
		bita #JOYFIRE1		; test for fire
		beq gameoverloop	; not pressed? check again

		ldy #0x0000
		jsr [delay]

		rts			; end of game

; draws a bit of the snake, tile in a. may be blank (0), maybe body or maybe
; head. b has position along snake array we want to draw.

drawsnakepart:	sta stamp,pcr		; save the tile to draw for stampat

		leax rowsnake,pcr	; setup row table pointer
		abx			; add (unsigned) the snake pos
		lda ,x			; and deref to get the row coord

		leax colsnake,pcr	; setup the col table pointer
		abx			; add (unsigned) the snake pos
		ldb ,x			; and deref to get the col coord

		lbsr stampat		; update screen with the new tile

		rts

; reads the current head position, and adds a new row and column to the
; position arrays, taking into account the direction the snake is moving.
; takes no parameters.

movesnake:	ldb headpos,pcr		; get the current head

		leax rowsnake,pcr	; setup row table pointer
		abx			; add (unsigned) the snake pos
		lda ,x			; and deref to get row of head
		adda rowdirection,pcr	; add the current direction (row)
		leax rowsnake,pcr	; setup table again
		incb			; because we need to wrap around
		abx			; but we are on the next index
		sta ,x			; and finally we can save into it

		ldb headpos,pcr		; same again but for cols

		leax colsnake,pcr	; ...
		abx			; ...
		lda ,x			; ...
		adda coldirection,pcr	; ...
		leax colsnake,pcr	; ...
		incb			; ...
		abx			; ...
		sta ,x			; ...

		inc headpos,pcr		; move the head to the next position
		rts			; will wrap 255->0

; see what is at the tile where the head of the snake now is, setting a
; to the tile number, b is the position along the array

testcollide:	leax rowsnake,pcr	; setup row table pointer
		abx			; add (unsigned) the snake pos
		lda ,x			; and deref to get row of head

		leax colsnake,pcr	; setup col table pointer
		abx			; add (unsigned) the snake pos
		ldb ,x			; and deref to get col of head

		lbsr peekat		; get whats under the new head
		lda peek,pcr		; save it in a

		rts

; process a collision by looking at a

docollision:	cmpa #FOODTILE		; food for the nake?
		beq yumyum		; eat the food
		clra			; zero means deathh
docollisiono:	rts

yumyum:		inc snakelength,pcr	; snake grows as it eats
		lbsr placenewfood	; put some new food down
		ldx movementdelay,pcr	; get current snake speed
		leax -0x0040,x		; at 120 food it will be max speed 
		cmpx #0x0200		; up 16 times faster then at start
		bls yumyumo		; don't make delay too silly!
		stx movementdelay,pcr	; save it
yumyumo:	lda #1			; we dont die when eating food!
		bra docollisiono

; place some new food at a random empty place. returns with a nd b at food
; location.

placenewfood:	lda #FOODTILE
		sta stamp,pcr
tryplaceagain:	lbsr randomnumber
		anda #31
		tfr a,b
		lbsr randomnumber
		cmpa #24
		bhs tryplaceagain
		lbsr peekat
		tst peek,pcr
		bne tryplaceagain
		lbsr stampat
		rts

controlsnake:	lbsr readjoystick
		bita #JOYLEFT
		bne moveleft
		bita #JOYRIGHT
		bne moveright
		bita #JOYUP
		bne moveup
		bita #JOYDOWN
		bne movedown
controlsnakeo:	rts

moveleft:	lda #1
		bra moveleftright
moveright:	lda #-1
		bra moveleftright
moveup:		lda #1
		bra moveupdown
movedown:	lda #-1
		bra moveupdown

moveleftright:	cmpa coldirection,pcr
		beq controlsnakeo
		nega
		sta coldirection,pcr
		clr rowdirection,pcr
		bra controlsnakeo
moveupdown:	cmpa rowdirection,pcr
		beq controlsnakeo
		nega
		clr coldirection,pcr
		sta rowdirection,pcr
		bra controlsnakeo

randominit:	lda #42
		sta randomseed
		rts

randomnumber:	lda randomseed
		beq doeor
		asla
		beq noeor		; if the input was $80, skip the eor
		bcc noeor
doeor:		eora #0xf5
noeor:		sta randomseed

		rts

titlemessage:	.asciz ' SNAKE! '
livesmessage:	.asciz '     '

drawplayarea:	clra			; top left is 0, 0
		clrb			; ..
		pshs a,b		; push this on the u stack
		lda #23			; bottom right is 23, 31
		ldb #31			; ...
		pshs a,b		; push this on
		lbsr drawbox		; call the drawbox function
		leas 4,s		; reset the stack

		; title message over the top border
		lda #0			; top row
		ldb #16-4		; roughly centered..
		leax titlemessage,pcr	; get the location of the message
		lbsr printstrat		; and print it

		lda #23			; bottom row
		ldb #24			; at the right
		leax livesmessage,pcr	; get the location of the message
		lbsr printstrat		; and print it

		rts

showlives:	leas -1,s
		ldb #25
		lda #3
		sta ,s
showlivesn:	lda lives,pcr
		cmpa ,s
		bhs showlife
		lda #DEADSNAKETILE
		sta stamp,pcr
		bra showlivesstate
showlife:	lda #SNAKEHEADTILE
		sta stamp,pcr
showlivesstate:	lda #23
		lbsr stampat
		incb
		dec ,s
		bne showlivesn
showliveso:	leas 1,s
		rts

; Variables

lives:		.rmb 1			; number of lives left
movementdelay:	.rmb 2			; how long to pause between steps

rowsnake:	.rmb 256		; circular array for snake position
colsnake:	.rmb 256		; for rows and columns
headpos:	.rmb 1			; offset into arrays where head is
snakelength:	.rmb 1			; the length of the sanke

rowdirection:	.rmb 1			; either -1, 0 or 1 for row dir
coldirection:	.rmb 1			; either -1, 0 or 1 for col dir

randomseed:	.rmb 1			; seed, and last random made
