		.include 'include/system.inc'

		.globl wordtoaschex
		.globl bytetoaschex
		.globl printableasc
		.globl putstrdefio

		.globl _newlinez

		.area RAM

outputbuffer:	.rmb 256
disasscounter:	.rmb 2
outputpointer:	.rmb 2
addrmode:	.rmb 2
opcode:		.rmb 1
currentpage:	.rmb 2
indexcode:	.rmb 1
statementstart:	.rmb 2
statementend:	.rmb 2

		.area ROM

;;; Big old mnemonic table

abxn:		.asciz 'ABX'
adcan:		.asciz 'ADCA'
adcbn:		.asciz 'ADCB'
addan:		.asciz 'ADDA'
addbn:		.asciz 'ADDB'
adddn:		.asciz 'ADDD'
andan:		.asciz 'ANDA'
andbn:		.asciz 'ANDB'
andccn:		.asciz 'ANDCC'
asrn:		.asciz 'ASR'
asran:		.asciz 'ASRA'
asrbn:		.asciz 'ASRB'
beqn:		.asciz 'BEQ'
bgen:		.asciz 'BGE'
bgtn:		.asciz 'BGT'
bhin:		.asciz 'BHI'
bhsn:		.asciz 'BHS'
bitan:		.asciz 'BITA'
bitbn:		.asciz 'BITB'
blen:		.asciz 'BLE'
blon:		.asciz 'BLO'
blsn:		.asciz 'BLS'
bltn:		.asciz 'BLT'
bmin:		.asciz 'BMI'
bnen:		.asciz 'BNE'
bpln:		.asciz 'BPL'
bran:		.asciz 'BRA'
brnn:		.asciz 'BRN'
bsrn:		.asciz 'BSR'
bvcn:		.asciz 'BVC'
bvsn:		.asciz 'BVS'
clrn:		.asciz 'CLR'
clran:		.asciz 'CLRA'
clrbn:		.asciz 'CLRB'
cmpan:		.asciz 'CMPA'
cmpbn:		.asciz 'CMPB'
cmpdn:		.asciz 'CMPD'
cmpsn:		.asciz 'CMPS'
cmpun:		.asciz 'CMPU'
cmpxn:		.asciz 'CMPX'
cmpyn:		.asciz 'CMPY'
comn:		.asciz 'COM'
coman:		.asciz 'COMA'
combn:		.asciz 'COMB'
cwain:		.asciz 'CWAI'
daan:		.asciz 'DAA'
decn:		.asciz 'DEC'
decan:		.asciz 'DECA'
decbn:		.asciz 'DECB'
eoran:		.asciz 'EORA'
eorbn:		.asciz 'EORB'
exgn:		.asciz 'EXG'
incn:		.asciz 'INC'
incan:		.asciz 'INCA'
incbn:		.asciz 'INCB'
jmpn:		.asciz 'JMP'
jsrn:		.asciz 'JSR'
lbeqn:		.asciz 'LBEQ'
lbgen:		.asciz 'LBGE'
lbgtn:		.asciz 'LBGT'
lbhin:		.asciz 'LBHI'
lbhsn:		.asciz 'LBHS'
lblen:		.asciz 'LBLE'
lblon:		.asciz 'LBLO'
lblsn:		.asciz 'LBLS'
lbltn:		.asciz 'LBLT'
lbmin:		.asciz 'LBMI'
lbnen:		.asciz 'LBNE'
lbpln:		.asciz 'LBPL'
lbran:		.asciz 'LBRA'
lbrnn:		.asciz 'LBRN'
lbsrn:		.asciz 'LBSR'
lbvcn:		.asciz 'LBVC'
lbvsn:		.asciz 'LBVS'
ldan:		.asciz 'LDA'
ldbn:		.asciz 'LDB'
lddn:		.asciz 'LDD'
ldsn:		.asciz 'LDS'
ldun:		.asciz 'LDU'
ldxn:		.asciz 'LDX'
ldyn:		.asciz 'LDY'
leasn:		.asciz 'LEAS'
leaun:		.asciz 'LEAU'
leaxn:		.asciz 'LEAX'
leayn:		.asciz 'LEAY'
lslan:		.asciz 'LSLA'
lsln:		.asciz 'LSL'
lslbn:		.asciz 'LSLB'
lsrn:		.asciz 'LSR'
lsran:		.asciz 'LSRA'
lsrbn:		.asciz 'LSRB'
muln:		.asciz 'MUL'
negn:		.asciz 'NEG'
negan:		.asciz 'NEGA'
negbn:		.asciz 'NEGB'
nopn:		.asciz 'NOP'
oran:		.asciz 'ORA'
orbn:		.asciz 'ORB'
orccn:		.asciz 'ORCC'
pshsn:		.asciz 'PSHS'
pshun:		.asciz 'PSHU'
pulsn:		.asciz 'PULS'
pulun:		.asciz 'PULU'
roln:		.asciz 'ROL'
rolan:		.asciz 'ROLA'
rolbn:		.asciz 'ROLB'
rorn:		.asciz 'ROR'
roran:		.asciz 'RORA'
rorbn:		.asciz 'RORB'
rtin:		.asciz 'RTI'
rtsn:		.asciz 'RTS'
sbcan:		.asciz 'SBCA'
sbcbn:		.asciz 'SBCB'
sexn:		.asciz 'SEX'
stan:		.asciz 'STA'
stbn:		.asciz 'STB'
stdn:		.asciz 'STD'
stsn:		.asciz 'STS'
stun:		.asciz 'STU'
stxn:		.asciz 'STX'
styn:		.asciz 'STY'
suban:		.asciz 'SUBA'
subbn:		.asciz 'SUBB'
subdn:		.asciz 'SUBD'
swin:		.asciz 'SWI'
swi2n:		.asciz 'SWI2'
swi3n:		.asciz 'SWI3'
syncn:		.asciz 'SYNC'
tfrn:		.asciz 'TFR'
tstn:		.asciz 'TST'
tstan:		.asciz 'TSTA'
tstbn:		.asciz 'TSTB'

;;; Machine code instruction tables

; first struct is a page definition (default or page 10, 11 etc)

.macro		pagedef opcode, page
		.byte opcode
		.word page
.endm

; second struct has no prefix and is just a list of any opcodes

.macro		noprefix opcodetab, addrmodehandler
		.word opcodetab		; opcode table
		.word addrmodehandler	; post opcode bytes handler
.endm

; third struct is one with a first nibble prefix filter

.macro		prefix opcodeprefix, opcodetab, addrmodehandler
		.byte opcodeprefix	; low nibble in opcode
		.word opcodetab		; opcode table
		.word addrmodehandler	; post opcode bytes handler
.endm

; this is an actual opcodes: binary value to opcode string

.macro		mc opcode, mn
		.byte opcode		; opcode byte value (maybe masked)
		.word mn		; opcode asciz string
.endm

; all the pages, mapping the first opcode byte to a page

pagedefs:	pagedef 0x10, page10
		pagedef 0x11, page11
		pagedef 0x00, 0x00

; "pages" are collections of noprefix'ed and prefix'ed tables

defaultpage:	.word noprefixtab, prefixtab
page10:		.word p10noprefixtab, p10prefixtab
page11:		.word p11noprefixtab, p11prefixtab

; these are the "randoms" which have no prefix block

noprefixtab:	noprefix inherenttab, nullhandle
		noprefix indexedtab, indexedhandle
		noprefix immedtab, immedhandle
		noprefix regimmedtab, regimmedhandle
		noprefix stkimmedtab, stkimmedhandle
		noprefix relbytetab, relbytehandle
		noprefix relwordtab, relwordhandle
		noprefix 0xffff, 0x0000

; we sort these by addressing mode. opcode "blocks" make up the bulk of the
; number space, luckily

prefixtab:	prefix 0xb0, regaopstab, extendedhandle
		prefix 0xf0, regbopstab, extendedhandle
		prefix 0x70, memopstab, extendedhandle

		prefix 0x00, memopstab, directhandle
		prefix 0x90, regaopstab, directhandle
		prefix 0xd0, regbopstab, directhandle

		prefix 0x80, regaopstab, immedhandle
		prefix 0xc0, regbopstab, immedhandle

		prefix 0x60, memopstab, indexedhandle
		prefix 0xa0, regaopstab, indexedhandle
		prefix 0xe0, regbopstab, indexedhandle

		prefix 0xff, 0x0000, 0x0000

; inherent opcode table - opcodes with no parameter - not masked

inherenttab:	mc 0x12, nopn
		mc 0x13, syncn
		mc 0x19, daan
		mc 0x1d, sexn
		mc 0x39, rtsn
		mc 0x3a, abxn
		mc 0x3b, rtin
		mc 0x3d, muln
		mc 0x3f, swin
		mc 0x40, negan
		mc 0x43, coman
		mc 0x44, lsran
		mc 0x46, roran
		mc 0x47, asran
		mc 0x48, lslan
		mc 0x49, rolan
		mc 0x4a, decan
		mc 0x4c, incan
		mc 0x4d, tstan
		mc 0x4f, clran
		mc 0x50, negbn
		mc 0x53, combn
		mc 0x54, lsrbn
		mc 0x56, rorbn
		mc 0x57, asrbn
		mc 0x58, lslbn
		mc 0x59, rolbn
		mc 0x5a, decbn
		mc 0x5c, incbn
		mc 0x5d, tstbn
		mc 0x5f, clrbn
		mc 0xff, 0x0000

; special indexed opcode - no mask

indexedtab:	mc 0x30, leaxn
		mc 0x31, leayn
		mc 0x32, leasn
		mc 0x33, leaun
		mc 0xff, 0x0000

; special imediate (1 byte) opcodes - no mask

immedtab:	mc 0x1a, orccn
		mc 0x1c, andccn
		mc 0x3c, cwain
		mc 0xff, 0x0000

; special immediate (1 byte) opcodes used in reg moving - no mask

regimmedtab:	mc 0x1e, exgn
		mc 0x1f, tfrn
		mc 0xff, 0x0000

; special immediate (1 byte) opcodes used in stacking - no mask

stkimmedtab:	mc 0x34, pshsn
		mc 0x35, pulsn
		mc 0x36, pshun
		mc 0x37, pulun
		mc 0xff, 0x0000

; special relative branches (1 byte offset)

relbytetab:	mc 0x20, bran
		mc 0x21, brnn
		mc 0x22, bhin
		mc 0x23, blsn
		mc 0x24, bhsn
		mc 0x25, blon
		mc 0x26, bnen
		mc 0x27, beqn
		mc 0x28, bvcn
		mc 0x29, bvsn
		mc 0x2a, bpln
		mc 0x2b, bmin
		mc 0x2c, bgen
		mc 0x2d, bltn
		mc 0x2e, bgtn
		mc 0x2f, blen
		mc 0x8d, bsrn
		mc 0xff, 0x0000

; same again, but two bytes - still no mask

relwordtab:	mc 0x16, lbran
		mc 0x17, lbsrn
		mc 0xff, 0x0000

; suffix (multiple prefixes) block of memery operations

memopstab:	mc 0x00, negn
		mc 0x03, comn
		mc 0x04, lsrn
		mc 0x06, rorn
		mc 0x07, asrn
		mc 0x08, lsln
		mc 0x09, roln
		mc 0x0a, decn
		mc 0x0c, incn
		mc 0x0d, tstn
		mc 0x0e, jmpn
		mc 0x0f, clrn
		mc 0xff, 0x0000

; stuff that operates on the a register is common between 3 addr mode

regaopstab:	mc 0x00, suban
		mc 0x01, cmpan
		mc 0x02, sbcan
		mc 0x03, subdn
		mc 0x04, andan
		mc 0x05, bitan
		mc 0x06, ldan
		mc 0x07, stan
		mc 0x08, eoran
		mc 0x09, adcan
		mc 0x0a, oran
		mc 0x0b, addan
		mc 0x0c, cmpxn
		mc 0x0d, jsrn		; 0x8d is bsr with no prefix
		mc 0x0e, ldxn
		mc 0x0f, stxn
		mc 0xff, 0x0000

; stuff that operates on the b register is common too

regbopstab:	mc 0x00, subbn
		mc 0x01, cmpbn
		mc 0x02, sbcbn
		mc 0x03, adddn
		mc 0x04, andbn
		mc 0x05, bitbn
		mc 0x06, ldbn
		mc 0x07, stbn
		mc 0x08, eorbn
		mc 0x09, adcbn
		mc 0x0a, orbn
		mc 0x0b, addbn
		mc 0x0c, lddn
		mc 0x0d, stdn
		mc 0x0e, ldun
		mc 0x0f, stun
		mc 0xff, 0x0000

; page 10 noprefixe and prefixe tables

p10noprefixtab:	noprefix p10relwordtab, relwordhandle
		noprefix p10inherenttab, nullhandle
		noprefix 0xffff, 0x0000

p10prefixtab:	prefix 0x80, p10regatab, immedhandle
		prefix 0x90, p10regatab, directhandle
		prefix 0xa0, p10regatab, indexedhandle
		prefix 0xb0, p10regatab, extendedhandle
		prefix 0xc0, p10regbtab, immedhandle
		prefix 0xd0, p10regbtab, directhandle
		prefix 0xe0, p10regbtab, indexedhandle
		prefix 0xf0, p10regbtab, extendedhandle
		prefix 0xff, 0x0000, 0x0000

; page 10 word relative opcoes

p10relwordtab:	mc 0x21, lbrnn
		mc 0x22, lbhin
		mc 0x23, lblsn
		mc 0x24, lbhsn
		mc 0x25, lblon
		mc 0x26, lbnen
		mc 0x27, lbeqn
		mc 0x28, lbvcn
		mc 0x29, lbvsn
		mc 0x2a, lbpln
		mc 0x2b, lbmin
		mc 0x2c, lbgen
		mc 0x2d, lbltn
		mc 0x2e, lbgtn
		mc 0x2f, lblen
		mc 0xff, 0x0000

; page 10 inherent opcodes

p10inherenttab:	mc 0x3f, swi2n
		mc 0xff, 0x0000

p10regatab:	mc 0x03, cmpdn
		mc 0x0c, cmpyn
		mc 0x0e, ldyn
		mc 0x0f, styn
		mc 0xff, 0x0000

p10regbtab:	mc 0x0e, ldsn
		mc 0x0f, stsn
		mc 0xff, 0x0000

; page 11 noprefix and prefix tables

p11noprefixtab:	noprefix p11inherenttab, nullhandle
		noprefix 0xffff, 0x000

p11prefixtab:	prefix 0x80, p11regtab, immedhandle
		prefix 0x90, p11regtab, directhandle
		prefix 0xa0, p11regtab, indexedhandle
		prefix 0xb0, p11regtab, extendedhandle
		prefix 0xff, 0x0000, 0x0000

p11inherenttab:	mc 0x3f, swi3n
		mc 0xff, 0x0000

p11regtab:	mc 0x03, cmpun
		mc 0x0c, cmpsn
		mc 0xff, 0x0000

; handy strings

spacemsg:	.asciz ' '
ehmsg:		.asciz '???'
colonmsg:	.asciz ':'
commamsg:	.asciz ','
hexmsg:		.asciz '$'
directmsg:	.asciz '<'
immedmsg:	.asciz '#'
negativemsg:	.asciz '-'

; register names

ccregmsg:	.asciz 'CC'
aregmsg:	.asciz 'A'
bregmsg:	.asciz 'B'
dpregmsg:	.asciz 'DP'
dregmsg:	.asciz 'D'
xregmsg:	.asciz 'X'
yregmsg:	.asciz 'Y'
sregmsg:	.asciz 'S'
uregmsg:	.asciz 'U'
pcregmsg:	.asciz 'PC'

; disassemble from u, count of x instructions

disassentry::	stx disasscounter	; save the instruction count
		
		lbsr outputinit		; setup the buffer and pointer

		stu statementstart	; save the address of the first byte
		tfr u,d			; get address of this line
		lbsr wordtoaschex	; print the address into the buffer
		stx outputpointer	; save it away
		ldx #colonmsg		; this is the "label"
		lbsr outputappend	; so it needs a colon
		ldx #spacemsg		; and a space would be nice
		lbsr outputappend	; add it
		lbsr outputappend	; and one more

		ldy #defaultpage	; set the default page
		sty currentpage		; and save it away

		lda ,u+			; get the opcode byte
		sta opcode		; save it (we'll need it later)

		ldy #pagedefs		; we need to loop on the page defs
pagedefloop:	tst ,y			; end of the list?
		beq setcurrentpage	; if so then exit loop
		cmpa ,y+		; see if we have a match to the page
		bne nopagedefmatch	; if not...
		ldy ,y			; if we do, then deref to get page
		sty currentpage		; save it (pointer to nopreixtab)
		lda ,u+			; get the new opcode
		sta opcode		; and save it
		bra setcurrentpage	; hop forward to setting current page
nopagedefmatch:	leay 2,y		; hop over the noprefix pointer
		bra pagedefloop		; back for more (there's only 2...)

setcurrentpage:	ldy [currentpage]	; get the non prefix table
		lda opcode		; get the opcode again
		
noprefixloop:	ldx ,y			; get the opcode pointer
		cmpx #0xffff		; 0xffff marks this one's end
		beq noprefixout		; if we are at the end, leave
		lbsr procaddrmode	; process this opcode table
		beq prefixout		; if zero then we proc'd a opcode
		leay 4,y		; y points to the noprefix table
		bra noprefixloop	; not the opcode table

noprefixout:	ldy currentpage		; get the current page again
		leay 2,y		; the preifxtab is next
		ldy ,y			; deref to get it
		lda opcode		; get the full opcode again
		anda #0xf0		; we just want the prefix

prefixloop:	ldb ,y			; get this prefix
		cmpb #0xff		; 0xff marks the end of the table
		beq nomatch		; if we are at the end ??? to output
		cmpa ,y+		; and see if it matches the prefix
		bne prefixnotfound	; not found, so onward to next one

		lda opcode		; our opcode has the right prefix
		anda #0x0f		; mask off the interesting part
		lbsr procaddrmode	; and process the opcode table
		beq prefixout		; if zero then we proc'd a opcode
		
prefixnotfound:	leay 4,y		; hop over to the next prefix
		bra prefixloop		; and go back for more

nomatch:	ldx #ehmsg		; '???'
		lbsr outputappend	; oh dear

prefixout:	stu statementend	; save the end address

		lda #40			; move to the middle of the screen
		lbsr outputmoveto	; ...

		ldy statementstart	; reset instruction counter

rawbyteloop:	lda ,y+			; get the byte from teh stream
		ldx outputpointer	; get the current position
		lbsr bytetoaschex	; convert byte to ascii
		stx outputpointer	; save the new position

		ldx #spacemsg		; pad with a space
		lbsr outputappend	; ..

		cmpy statementend	; see if we are at the end
		bne rawbyteloop		; if not, back for more raw bytes

		lda #60			; move to 3/4 across the screen
		lbsr outputmoveto	; ...

		ldy statementstart	; reset instruction counter

rawbyteascloop:	lda ,y+			; get the byte from the stream
		lbsr printableasc	; convert it to printable ascii
		lbsr outputasc		; add it ot the output
		
		cmpy statementend	; see if we are the end 
		bne rawbyteascloop	; if not, back for more ascii chars

		ldx #_newlinez		; we want a nice newline
		lbsr outputappend	; between the statements
		ldx outputpointer	; get the current pos
		clr ,x			; so we can (finally) add a null

		ldy #outputbuffer	; send the whole line
		lbsr putstrdefio	; to the terminal

		ldx disasscounter	; decrement the opcode
		leax -1,x		; ..
		stx disasscounter	; counter

		lbne disassentry	; back for more opcodes, maybe

		rts

; process a table of opcodes. y will point at the [no]prefix "description" -
; first word is the opcode table pointer, and 2nd is the handler for
; subsequent bytes

procaddrmode:	sty addrmode		; save the description pointer
		ldy ,y			; deref into te opcode table
procaddrloop:	ldb ,y			; load the first opcode
		cmpb #0xff		; end of the opcode table?
		beq procaddrmodeo	; if so exit
		cmpa ,y+		; matches our (maybe maked) opcode?
		beq opcodefound		; if so deal with it
		leay 2,y		; if not we need to hop the mn...
		bra procaddrloop	; and go back for more
opcodefound:	ldx ,y			; if it did, deref to mn string
		lbsr outputappend	; and append it
		ldx #spacemsg		; and follow with a space
		lbsr outputappend	; ...
		ldy addrmode		; restore the original desc pointer
		leay 2,y		; move along to the handler pointer
		ldx ,y			; which must be de-referened
;		ldx [2,y]		; derefence into the handler pointer
		jsr ,x			; and call it
		orcc #0x04		; we processed an opcode -> set zero
		rts			; so we can now output the line
procaddrmodeo:	ldy addrmode		; restore once more so caller
		andcc #0xfb		; and mark it as not proc'd -> !zero
		rts

; post opcode bytes handler that does nothing at all

nullhandle:	rts			; dummy for immediates

; post opode byte handler for single byte offsets

relbytehandle:	lda ,u+			; get the byte offset
		leax a,u
		tfr x,d
		lbsr outputword		; print the offset into the buffer
		rts

; post opode byte handler for word offsets

relwordhandle:	ldd ,u++		; get the byte offset
		leax d,u
		tfr x,d
		lbsr outputword		; print the offset into the buffer
		rts

; post opcode bytes handler for word address

extendedhandle:	ldd ,u++		; get the word, advancing u
		lbsr outputword
		rts

directhandle:	ldx #directmsg		; '<'
		lbsr outputappend
		lda ,u+			; get the byte address, advancing u
		lbsr outputbyte
		rts

immedhandle:	ldx #immedmsg		; '#'
		lbsr outputappend	; append that
		lda opcode		; get the original opcode
		anda #0x0f		; mask off the low byte
		cmpa #0x03		; this is subd, 2 bytes
		beq immedword		; ...
		cmpa #0x0c		; cmpx is also 2 bytes
		beq immedword		; ...
		cmpa #0x0e		; ldx is also 2 bytes
		beq immedword		; ...
		lda ,u+			; otherwise it must be 1 byte
		lbsr outputbyte		; convert it
immedout:	rts			; done
immedword:	ldd ,u++		; for words, grab it to d
		lbsr outputword		; convert it
		rts

; this is for exg and tfr - ehmsg is ??? - the index is the post byte,
; masked for source and destination

regmovetab:	.word dregmsg, xregmsg, yregmsg, uregmsg
		.word sregmsg, pcregmsg, ehmsg, ehmsg
		.word aregmsg, bregmsg, ccregmsg, dpregmsg
		.word ehmsg, ehmsg, ehmsg, ehmsg

regimmedhandle:	ldb ,u			; get the post opcode byte
		ldy #regmovetab		; init the table pointer
		andb #0xf0		; mask off the high nibble
		lsrb			; shift it down four times
		lsrb			; ...
		lsrb			; ...
		lsrb			; ...
		lslb			; then back one, we have word ptrs
		leax [b,y]		; add to the table and deref
		lbsr outputappend	; this is the source
		ldx #commamsg		; and a comma
		lbsr outputappend	; ...
		ldb ,u+			; now get the original postbyte
		andb #0x0f		; and mask off the low nibble
		lslb			; times 2 because of word ptrs
		leax [b,y]		; deref again to get the destination
		lbsr outputappend	; ...
		rts

; stacking - pshs, puls, pshu, pulu - the table is a table of bits this time
; not offsets

sstackingtab:	.word ccregmsg, aregmsg, bregmsg, dpregmsg
		.word xregmsg, yregmsg, uregmsg, pcregmsg
ustackingtab:	.word ccregmsg, aregmsg, bregmsg, dpregmsg
		.word xregmsg, yregmsg, sregmsg, pcregmsg

stkimmedhandle: ldb #8			; 8 shifts for a byte
		lda opcode		; get the original opcode
		bita #0x02		; bit 1 0 means s stacking , else u
		beq sstacking		; it is pshs or puls
		ldy #ustackingtab	; so set the table pointer
		bra stackingstart	; hop hop
sstacking:	ldy #sstackingtab	; it is pshu or pulu
stackingstart:	lda ,u			; advance at the end not now
stackingloop:	rora			; rorate into carry
		bcc endstacking		; if 0, then we are not stacking
		ldx ,y			; deref to get the reg string
		lbsr outputappend	; append the reg name
		ldx #commamsg		; and we need a comma
		lbsr outputappend	; so add that
endstacking:	leay 2,y		; eitherway move index along
		decb			; and decrement bit counter
		bne stackingloop	; see if there is more bits
		tst ,u+			; now we can advance to next opcode
		beq stkimmedout		; if there was nothing to stack
		lbsr outputbackone	; don't move the cursor back one
stkimmedout:	rts			; out

; indexed mode decoder - the most complex handler by far

sindirectmsg:	.asciz '['
eindirectmsg:	.asciz ']'
incmsg:		.asciz '+'
incincmsg:	.asciz '++'
decmsg:		.asciz '-'
decdecmsg:	.asciz '--'

; the different indexing mode, 16 of them but a few are unused

offsettab:	.word indexreginc, indexregincinc, indexregdec, indexregdecdec
		.word indexreg, indexbreg, indexareg, indexinvalid
		.word indexbytereg, indexwordreg, indexinvalid, indexdreg
		.word indexbytepc, indexwordpc, indexinvalid, indexindirect

; the front end to the handler

indexedhandle:	lda ,u+			; grab the index code byte
		sta indexcode		; save it away
		bmi indexoffset		; bit7 set?
		anda #0x1f		; if not->offset is in this byte
		lbsr outputsignfive	; output just the low 5 bits
		ldx #commamsg		; then a comma
		lbsr outputappend	; ...
		bsr showindexreg	; and the register we are offsetting
		rts			; done
indexoffset:	bita #0x10		; bit4 set->
		beq notindirect		; means indirect mode is used
		ldx #sindirectmsg	; this is a '['
		lbsr outputappend	; add it to the output
notindirect:	anda #0x0f		; mask iff the low 4 bits
		lsla			; shift up to get index into tab
		ldx #offsettab		; setup the offset mode table
		ldx a,x			; add the offset type
		jsr ,x			; jump into the handler
		lda indexcode		; restore the index code again
		bita #0x10		; and test test for indirect
		beq indexout		; if not, then done
		ldx #eindirectmsg	; otherwise get the ']'
		lbsr outputappend	; and add it to the stream
indexout:	rts

; these are the four index registers

indexregtab:	.word xregmsg, yregmsg, uregmsg, sregmsg

; turns the index code byte into a register and outputs it

showindexreg:	lda indexcode		; load the index code back
		anda #0x7f		; mask off the high bit
		lsra			; shift down to the end
		lsra			; ...
		lsra			; ...
		lsra			; ,,,
		lsra			; ,,,
		lsla			; shift up, since tab is words
		ldx #indexregtab	; setup the tablee
		ldx a,x			; add the reg type and deref
		lbsr outputappend	; add the reg to the stream
		rts

; handlers for the difference indexing modes

indexinvalid:	ldx #ehmsg		; '???'
		lbsr outputappend	; output it
		rts

indexreginc:	ldx #commamsg		; ','
		lbsr outputappend	; output it
		bsr showindexreg	; then the register
		ldx #incmsg		; '+'
		lbsr outputappend	; output it
		rts

indexregincinc:	ldx #commamsg		; ','
		lbsr outputappend	; output it
		bsr showindexreg	; then the register
		ldx #incincmsg		; '++'
		lbsr outputappend	; output it
		rts

indexregdec:	ldx #commamsg		; ','
		lbsr outputappend	; output it
		ldx #decmsg		; '-'
		lbsr outputappend	; output it
		lbsr showindexreg	; then the register
		rts

indexregdecdec:	ldx #commamsg		; ','
		lbsr outputappend	; output it
		ldx #decdecmsg		; '--'
		lbsr outputappend	; output it
		lbsr showindexreg	; then the register
		rts

indexreg:	ldx #commamsg		; ','
		lbsr outputappend	; output it
		lbsr showindexreg	; then the register
		rts

indexbreg:	ldx #bregmsg		; 'B'
		lbsr outputappend	; output it
		ldx #commamsg		; ','
		lbsr outputappend	; output it
		lbsr showindexreg	; then the register
		rts

indexareg:	ldx #aregmsg		; 'A'
		lbsr outputappend	; output it
		ldx #commamsg		; ','
		lbsr outputappend	; output it
		lbsr showindexreg	; then the register
		rts

indexbytereg:	lda ,u+			; get the next byte
		lbsr outputsignbyte	; output the byte (with dollar)
		ldx #commamsg		; ','
		lbsr outputappend	; output it
		lbsr showindexreg	; then the register
		rts

indexwordreg:	ldd ,u++		; get the next two bytes
		lbsr outputsignword	; output the word
		ldx #commamsg		; ','
		lbsr outputappend	; output it
		lbsr showindexreg	; then the register
		rts

indexdreg:	ldx #dregmsg		; 'D'
		lbsr outputappend	; output it
		ldx #commamsg		; ','
		lbsr outputappend	; output it 
		lbsr showindexreg	; then the register
		rts

indexbytepc:	lda ,u+			; get the next byte
		lbsr outputsignbyte	; output the byte with dollar
		ldx #commamsg		; ','
		lbsr outputappend	; output it
		ldx #pcregmsg		; 'PC'
		lbsr outputappend	; output it
		rts

indexwordpc:	ldd ,u++		; get the next word
		lbsr outputsignword	; output the word with dollar
		ldx #commamsg		; ','
		lbsr outputappend	; output it
		ldx #pcregmsg		; 'PC'
		lbsr outputappend	; output it
		rts

indexindirect:	ldd ,u++		; get the next work
		lbsr outputword		; and output it
		rts

;;;

outputinit:	ldx #outputbuffer
		lda #80			; fill term width with spaces
		ldb #0x20		; 'space'
outputinitloop:	stb ,x+			; fill with a space
		deca			; upto 80 chars
		bne outputinitloop	; back for more
		clr ,x+			; add the terminator
		ldx #outputbuffer	; reset the buffer pointer
		stx outputpointer	; and save it to the start
		rts

outputappend:	pshs x,y,a
		tfr x,y			; on input x is the string to append
		ldx outputpointer	; but we need it in y
outputappendl:	lda ,y+
		beq outputappendo
		sta ,x+
		bra outputappendl
outputappendo:	stx outputpointer	; save the new position
		puls x,y,a
		rts

outputasc:	ldx outputpointer	; get the current position
		sta ,x+			; put 'a' in the stream
		stx outputpointer	; save the new position
		rts

outputsignfive:	ldx #hexmsg
		lbsr outputappend
		bita #0x10
		beq plusfive
		ldx #negativemsg
		lbsr outputappend
		eora #0x1f
		inca
plusfive:	ldx outputpointer
		lbsr bytetoaschex
		stx outputpointer
		rts

outputbyte:	ldx #hexmsg		; '$'
		lbsr outputappend	; output it
		ldx outputpointer	; get the current pointer
		lbsr bytetoaschex	; add the byte to the output
		stx outputpointer	; save the new pointer
		rts

outputsignbyte:	ldx #hexmsg
		lbsr outputappend
		tsta
		bpl plusbyte
		ldx #negativemsg
		lbsr outputappend
		coma
		inca
plusbyte:	ldx outputpointer
		lbsr bytetoaschex
		stx outputpointer
		rts


outputword:	ldx #hexmsg		; '$'
		lbsr outputappend	; output it
		ldx outputpointer	; get the current pointer
		lbsr wordtoaschex	; add the word to the output
		stx outputpointer	; save the new pointer
		rts

outputsignword:	ldx #hexmsg
		lbsr outputappend
		tsta
		bpl plusword
		ldx #negativemsg
		lbsr outputappend
		coma
		comb
		addd #1
plusword:	ldx outputpointer
		lbsr wordtoaschex
		stx outputpointer
		rts

outputbackone:	pshs x,a
		ldx outputpointer	; get the current position
		lda #0x20		; 'space'
		sta ,-x			; blank current pos and back move one
		stx outputpointer	; save the new position
		puls x,a
		rts

outputmoveto:	ldx #outputbuffer	; get the starting position
		leax a,x		; add the column offset
		stx outputpointer	; save it to the current position
		rts
