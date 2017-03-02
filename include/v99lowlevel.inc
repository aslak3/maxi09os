; v99(58) low level routines

; simple timing delay

.macro		sleep
		nop
		nop
		nop
.endm

; stores whats in register a in the v99 register

.macro		loadareg register
		sta VDIRECTPORT
		lda #register|0x80
		sta VDIRECTPORT
.endm

; stores the value in the v99 register

.macro		loadconstreg register, value
		lda #value
		sta VDIRECTPORT
		lda #register|0x80
		sta VDIRECTPORT
.endm

; gets the value of the status register

.macro		getstatusreg register
		lda #register
		loadareg VSTATUSREG
		lda VSTATUSPORT
.endm

.macro		writeaport0
		sta VPORT0
		sleep
.endm

.macro		readaport0
		lda VPORT0
.endm
