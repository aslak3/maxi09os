; virtual console (screen and keyboard) driver

; video ram (vram) layout:
;
; 0x0000 - patterns (font data)
; 0x8000 - console 0 text data
; 0x9000 - console 1 text data
; etc upto console 5

		.include 'include/hardware.inc'
		.include 'include/v99lowlevel.inc'
		.include 'include/system.inc'
		.include 'include/scancodes.inc'
		.include 'include/ascii.inc'
		.include 'include/debug.inc'

		.globl memoryalloc
		.globl memoryfree
		.globl currenttask
		.globl signalalloc
		.globl enable
		.globl disable
		.globl forbid
		.globl permit
		.globl initlist
		.globl addtail
		.globl remove
		.globl vinit
		.globl vsetcolours
		.globl vclear
		.globl vread
		.globl vwrite
		.globl vseekwrite

		.globl _devicenotimp
		.globl _driversignal
		.globl _mapscancode
		.globl _uartllopen
		.globl _uartllclose
		.globl _uartllsetbaud
		.globl _fontdata


CONSOLECOUNT	.equ 6			; the number of virtual consoles
PORTKEYBOARD	.equ PORTD		; the uart port attached to keybard
COLS		.equ 80			; number of columns of text
ROWS		.equ 24			; number of rows of text
HALF		.equ 12			; for scrolling half a screen
CURSORVAL	.equ 127		; the cursor pattern number

structstart	DEVICE_SIZE
member		CON_RX_BUF,32		; receive circular bufrer
member		CON_TX_BUF,32		; transmit circular buffer
member		CON_RX_COUNT_H,1	; handler receive counter
member		CON_TX_COUNT_H,1	; handler transmit counter
member		CON_RX_COUNT_U,1	; user receive counter
member		CON_TX_COUNT_U,1	; user transmit counter
member		CON_UNIT,1		; unit number
member		CON_CAPSLOCK,1		; caps lock on?
member		CON_VRAMADDR,2		; base vram address for this console
member		CON_CURSOR_ROW,1	; row position of cursor
member		CON_CURSOR_COL,1	; column position of cursor
member		CON_SCROLL_BIG,1	; big jumps when scrolling mode
structend	CON_SIZE

		.area RAM

condevices:	.rmb 2*CONSOLECOUNT	; all the port devices
kbdbaseaddr:	.rmb 2			; uart port d base
activeconsole:	.rmb 1			; the active console
linestarts:	.rmb 2*ROWS		; 24 line offsets, not per console
scrollbuffer:	.rmb (ROWS-1)*COLS	; holding area used by scrolling

		.area ROM

switchtable:	.byte 0
		.byte KEY_F1
		.byte 1
		.byte KEY_F2
		.byte 2
		.byte KEY_F3
		.byte 3
		.byte KEY_F4
		.byte 4
		.byte KEY_F5
		.byte 5
		.byte KEY_F6
		.byte 0xff		; end of table of switch scancodes

; palette for console - traditional white text on black background

twocolpalette:	.byte 0x00, 0x00, 0x00  ; black background
		.byte 0x07, 0x07, 0x07  ; white text

; base addresses of each console in vram - could be generated by code
; but this will use less bytes (probably)

convramtable:	.word 0x1000
		.word 0x2000
		.word 0x3000
		.word 0x4000
		.word 0x5000
		.word 0x6000

; table of vidbaseregister values for each console
; format is: 0, A16, A15, A14, A13, A12, 1, 1

convbasetable:	.byte 0b00000111	; 0x1000
		.byte 0b00001011	; 0x2000
		.byte 0b00001111	; 0x3000
		.byte 0b00010011	; 0x4000
		.byte 0b00010111	; 0x5000
		.byte 0b00011011	; 0x6000

; console driver structure

_consoledef::	.word consoleopen
		.word consoleprep
		.asciz "console"

; consoleprepare - open the uart and init the display, this is global to
; all consoles

consoleprep:	pshs a,b,x,y,u
		debug ^'Console prep start',DEBUG_DRIVER
		lda #PORTKEYBOARD	; open the port attached to...
		lbsr _uartllopen	; the keyboard mcu
		sty kbdbaseaddr		; save the base address
		ldb #B9600		; the mcu currently uses 9600...
		lbsr _uartllsetbaud	; for its baud rate
		lbsr vinit		; clear video memory, center screen
		lda #0b00001000		; 64kbyte (by 4 bit) memories
		loadareg VMODE2REG 	; set this before doing memory io
		ldy #0			; 0 byte control codes
		ldu #8*32		; 32 characters of empty font data
		lbsr vclear		; clear it
		ldx #_fontdata		; the msx font data in mpu ram
		ldy #8*32		; skip 32 chars worth; control codes
		ldu #8*96		; 96 characters of font data
		lbsr vwrite		; set up the font data in vram
		lda #24			; 24 lines on the screen
		ldx #linestarts		; start of offset table
		ldy #0x0000		; pos of first column of each row
1$:		sty ,x++		; store the pos in the table
		leay COLS,y		; COLS coloumns to a row
		deca			; decrement row counter
		bne 1$			; back to the next row?
		clr activeconsole	; start on console 0 though not open
		lbsr showactive		; show this unopen console
		debug ^'Console prep end',DEBUG_DRIVER
		puls a,b,x,y,u
		rts

; console open - open the console unit in a reg, returning the device in x
; as per sysopen. b contains the scroll mode (0 for one line, not 0 for
; half of a screen at a time)

consoleopen:	ldx #CON_SIZE		; allocate the device struct
		lbsr memoryalloc	; get the memory for the struct
		stb CON_SCROLL_BIG,x	; should we do big scrolls?
		ldy currenttask		; get the current task
		sty DEVICE_TASK,x	; save it so we can signal it
		clr CON_RX_COUNT_H,x	; clear all buffer counters
		clr CON_TX_COUNT_H,x	; ...
		clr CON_RX_COUNT_U,x	; ...
		clr CON_TX_COUNT_U,x	; ...
		clr CON_CAPSLOCK,x	; caps lock off by default
		sta CON_UNIT,x		; save the console port
		lsla			; two bytes for a pointer
		ldy #convramtable	; table of base addresses
		ldy a,y			; get start address of this console
		sty CON_VRAMADDR,x	; save it in the structure
		ldy #condevices		; uart device pointer table
		stx a,y			; save the device pointer
		ldy #consoleclose	; save the close pointer
		sty DEVICE_CLOSE,x	; ... in the device struct
		ldy #consoleread	;  save the read pointer
		sty DEVICE_READ,x	; ... in the device struct
		ldy #consolewrite	; save the write pointer
		sty DEVICE_WRITE,x	; ... in the device struct
		ldy #_devicenotimp	; not implemented ,,,
		sty DEVICE_SEEK,x	; seek
		sty DEVICE_CONTROL,x	; and control
		lbsr signalalloc	; get a signal bit
		sta DEVICE_SIGNAL,x	; save it in the device struct
		lbsr clearconsole	; clear the newly opened console
		setzero			; 0 is good
		rts
1$:		ldx #0			; return 0
		setnotzero		; not 0 is bad - port is in use
		rts

; console close - give it the device in x

consoleclose:	lbsr memoryfree		; free the open device handle
		rts

; console read - get the last char in the buffer in a

consoleread:	pshs b,u
		lbsr disable		; into critical section
		ldb CON_RX_COUNT_U,x	; get counter
		cmpb CON_RX_COUNT_H,x	; compare..,
		beq gotnodata		; no character? then return
		leau CON_RX_BUF,x	; get the buffer
		lda b,u			; get the last char written to buf
		incb			; move along to the next
		andb #31		; wrapping to 32 byte window
		stb CON_RX_COUNT_U,x	; and save it
		cmpa #ASC_BREAK		; look for break
		beq gotbreak		; got it?
		bra consolereadoz	; got data in a, out with zero
gotbreak:	lda #IO_ERR_BREAK	; send back break 
		bra consolereadonz	; error state
gotnodata:	lda #IO_ERR_WAIT	; send back wait
consolereadonz:	lbsr enable		; out of critical section
		setnotzero		; no data, error state
		bra consolereadout
consolereadoz:  lbsr enable		; out of critical section
		setzero			; got data
consolereadout:	puls b,u
		rts

; write to the device in x, reg a

consolewrite:	pshs a,x,y,u
		lbsr forbid		; critical section due to vdc access
		cmpa #ASC_CR		; is it a return?
		beq handlecr		; if so, deal with it
		cmpa #ASC_LF		; is it a line feed?
		beq handlelf		; if so, deal with it
		cmpa #ASC_BS		; or a back-space?
		beq handlebs		; if so, deal with it
		cmpa #ASC_FF		; clear screen?
		beq handleff		; if so, deal with it
		cmpa #ASC_HT		; tab
		beq handleht
		bita #0x80		; test high bit
		bne consolewriteo	; skip high bit set char
		tsta			; check for ASC_NUL
		beq consolewriteo	; ignore
		bita #0xe0		; check the low 32 chars
		beq handlecontrol	; handle 0 to 31 
handleregular:	lbsr seekcursor		; otherwise, move to the current pos
		writeaport0		; and write it to the vram
		lda #CURSORVAL		; it is followed it by a cursor
		writeaport0		; and write the cursor
		lda CON_CURSOR_COL,x	; get the current cursor pos
		inca			; add one
		sta CON_CURSOR_COL,x	; and save it
		cmpa #COLS		; moved off the end of the row?
		beq newline		; if so, we need to wrap the line
consolewriteo:	lbsr permit		; end of vdc critical section
		puls a,x,y,u
		setzero
		rts
		
handlecr:	lbsr blankcursor	; blank current cursor position
		clr CON_CURSOR_COL,x	; move cursor to start of row
		bra consolewriteo

newline:	clr CON_CURSOR_COL,x	; move cursor to left of row
handlelf:	lda CON_CURSOR_ROW,x	; get current row position
		inca			; add one
		sta CON_CURSOR_ROW,x	; save new position
		cmpa #ROWS		; have we moved past the end?
		bne newlineout		; if not, we are finished
		lbsr scrollup		; otherwise we need to scroll!

newlineout:	bra consolewriteo

handlebs:	lbsr blankcursor	; blank out old cursor pos
		tst CON_CURSOR_COL,x	; were we at the start of a row?
		beq oldline		; if yes, move to end of prev row
		dec CON_CURSOR_COL,x	; otherwise move left
		lbsr drawcursor		; and draw the new cursor pos
		bra consolewriteo
oldline:	lda #COLS-1		; last coloumn on a row
		sta CON_CURSOR_COL,x	; save the cursor position
		dec CON_CURSOR_ROW,x	; back one line
		bra consolewriteo

handleff:	lbsr clearconsole	; formfeed - clear console
		bra consolewriteo

handleht:	lbsr blankcursor	; blank current cursor positionlda CON_CURSOR_COL,x	; get current col position
		lda CON_CURSOR_COL,x	; get current col position
		adda #8			; move across 8 chars
		anda #0xf8		; round back to nearest 8
		sta CON_CURSOR_COL,x	; and save it
		cmpa #COLS		; moved off the end of the row?
		beq newline		; if so, we need to wrap the line
		lbsr drawcursor		; and draw the new cursor pos
		bra consolewriteo

handlecontrol:	ora #0x40		; switch to the caps char set
		bra handleregular

; updates the vdc regsiters to show the active console

showactive:	pshs a,x,y
		lda #0b00000100		; text 2 settings (80 columns)
		loadareg VMODE0REG	; set this in mode 0 register
		lda #0b01010000		; bl=1, enable display
		loadareg VMODE1REG	; set this in mode 1 register
		lda #0b00001000		; 64kbyte (by 4 bit) memories
		loadareg VMODE2REG 	; set this in mode 2 register
		lda #0b00000010		; nt=1, enable pal mode
		loadareg VMODE3REG	; set this in mode 3 register
		clra			; patterns are at the start of vram
		loadareg VPATTBASEREG	; bottom half of vram - patterns
		ldx #twocolpalette	; set the colour reg pointer
		ldy #2			; 2 colours
		lbsr vsetcolours	; set the 2 colourscolours
		lda #0x10		; foreground=white, background=black
		loadareg VCOLOUR1REG	; set the text colour register
		lda activeconsole	; get the current console
		ldx #convbasetable	; uart device pointer table
		lda a,x			; two bytes for a pointer
		loadareg VVIDBASEREG	; top half, 6 consoles of video
		puls a,x,y
		rts

; clear the console at x, which may be active

clearconsole:	pshs y,u
		clr CON_CURSOR_ROW,x	; home the cursor to top
		clr CON_CURSOR_COL,x	; ... left		
		ldy CON_VRAMADDR,x	; base address of this console
		ldu #ROWS*COLS		; number of bytes for a scren
		lbsr forbid		; enter critical vdc section
		lbsr vclear		; zero the screen data
		lbsr permit		; leave critical vdc section
		puls y,u
		rts

; move the displayed cursor to its current position for console device x
; vram address is calculated from: linestarts[row] + col + console base

seekcursor:	pshs a,b,y
		ldb CON_CURSOR_ROW,x	; get the row number
		lslb			; offset table is in words
		ldy #linestarts		; start of table of offsets
		ldy b,y			; get the start of the row
		ldb CON_CURSOR_COL,x	; get the column number
		leay b,y		; and add it
		ldd CON_VRAMADDR,x	; get the base address
		leay d,y		; and add the base address
		lbsr vseekwrite		; move the writing position
		puls a,b,y
		rts

; blanks (by writing a 0) to the current cursor position

blankcursor:	pshs a
		lbsr seekcursor		; update 
		clra			; we are blanking
		writeaport0		; and zero the vram location
		puls a
		rts

; draws the cursor at its current position

drawcursor:	pshs a
		lbsr seekcursor		; update
		lda #CURSORVAL		; we are drawing the cursor (box)
		writeaport0		; draw it
		puls a
		rts

; shift the diplay, referenced by the device at x, up by either one row
; or half the screen, based on what is configured

scrollup:	pshs a
		lda CON_SCROLL_BIG,x	; get the scroll mode
		tsta			; see what mode it is
		beq 1$			; not big?
		lbsr scrolluphalf	; big, so scroll half
		lda #ROWS-HALF		; move the cursor to half way ...
		bra scrollupout		; ... down
1$:		lbsr scrollupone	; otherwise, scrol one row
		lda #ROWS-1		; and move the cursor ...
scrollupout:	sta CON_CURSOR_ROW,x	; to the bottom most row
		puls a
		rts

; scroll the screen up by half (12 rows)
		
scrolluphalf:	pshs x,y,u
		ldy CON_VRAMADDR,x	; get the base address
		leay HALF*COLS,y	; move to half way in
		ldx #scrollbuffer	; our temp location for the row
		ldu #(ROWS-HALF)*COLS	; set up the length counter
		lbsr vread		; read in this half
		leay -(ROWS-HALF)*COLS,y; move to the top half
		ldx #scrollbuffer	; reset the temp row pointer 
		ldu #(ROWS-HALF)*COLS	; set up the length counter
		lbsr vwrite		; write out, offset half
		leay (ROWS-HALF)*COLS,y	; move back to the second half
		ldu #HALF*COLS		; which we are clearing
		lbsr vclear		; clear this half for new text
		puls x,y,u
		rts

; scroll the screen up by one row

scrollupone:	pshs x,y,u
		ldy CON_VRAMADDR,x	; get the base address
		leay 1*COLS,y		; move to the start of the 2nd row
		ldx #scrollbuffer	; our temp location for the row
		ldu #(ROWS-1)*COLS	; set up the length counter
		lbsr vread		; read in the rest of the rows
		leay -1*COLS,y		; write into the previous row
		ldx #scrollbuffer	; reset the temp row pointer 
		ldu #(ROWS-1)*COLS	; set up the length counter
		lbsr vwrite		; write out, offset one row
		leay (ROWS-1)*COLS,y	; move to next row for reading
		ldu #1*COLS		; which we are clearing
		lbsr vclear		; clear this row for new text
		puls x,y,u
		rts

;;; INTERRUPT

; handle receive interrupts on consoe uart

_conrxhandler::	debug ^'Console in UART RX handler',DEBUG_INT
1$:		ldy kbdbaseaddr		; get the base address
		lda LSR16C654,y		; get the current status
		debugreg ^'LSR: ',DEBUG_INT,DEBUG_REG_A
		bita #0b0000011		; look for rx state
		lbeq 4$			; bit clear? no data, out	
		lda RHR16C654,y		; get the scancode byte from the port
		debugreg ^'RHR: ',DEBUG_INT,DEBUG_REG_A
		ldy #switchtable	; setup table pointer
2$:		ldb ,y+
		cmpb #0xff		; end of table marker
		lbeq 3$			; end of list, no match
		cmpa ,y+
		bne 2$			; back for more
		debugreg ^'Switching to console: ',DEBUG_INT,DEBUG_REG_B
		stb activeconsole	; save new console number
		lbsr showactive		; show this console on the vdc
		lbra 5$			; finished
3$:		ldx #condevices		; the open devices table
		ldb activeconsole	; get this again
		lslb			; 2 bytes for a pointer
		ldx b,x			; get the device for the active con
		lbeq 5$			; ignore not open consoles
		debug ^'Console is owned',DEBUG_INT
		lbsr _mapscancode	; translate the scancode in a
		beq 5$			; not a printable char
		ldb CON_RX_COUNT_H,x	; get current count of bytes
		leau CON_RX_BUF,x	; get the buffer
		sta b,u			; save the new char in the buffer
		incb			; we got a char
		andb #31		; wrap 0->31
		stb CON_RX_COUNT_H,x	; save the buffer write count
		cmpb CON_RX_COUNT_U,x	; get current user pointer
		lbne 1$			; back for more chars unless overrun
4$:		ldx #condevices		; get the console devices table
		ldb activeconsole	; get this again
		lslb			; 2 bytes for a pointer
		ldx b,x			; get the device for the active con
		beq 5$			; ignore not open consoles
		debugreg ^'Signaling owner of console: ',DEBUG_INT,DEBUG_REG_X
		lsrb
		lbsr _driversignal	; signal the task that owns it
		debug ^'Leaving console handler',DEBUG_INT
5$:		rts

