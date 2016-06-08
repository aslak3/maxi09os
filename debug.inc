; debug - port c output

.macro		debug thing
;		pshs x
;		ldx thing
;		lbsr debugprint
;		puls x
.endm

.macro		debugx
;		lbsr debugprintx
.endm

.macro		debugy
;		lbsr debugprinty
.endm

.macro		debuga
;		lbsr debugprinta
.endm

.macro		debugb
;		lbsr debugprintb
.endm
