; ascii constants

; standard 0 to 32 control codes (including space)

ASC_NUL		.equ 0x00
ASC_SOH		.equ 0x01
ASC_STX		.equ 0x02
ASC_ETX		.equ 0x03
ASC_EOT		.equ 0x04
ASC_ENQ		.equ 0x05
ASC_ACK		.equ 0x06
ASC_BEL		.equ 0x07
ASC_BS		.equ 0x08
ASC_HT		.equ 0x09
ASC_LF		.equ 0x0a
ASC_VT		.equ 0x0b
ASC_FF		.equ 0x0c
ASC_CR		.equ 0x0d
ASC_SO		.equ 0x0e
ASC_SI		.equ 0x0f
ASC_DLE		.equ 0x10
ASC_DC1		.equ 0x11
ASC_DC2		.equ 0x12
ASC_DC3		.equ 0x13
ASC_DC4		.equ 0x14
ASC_NAK		.equ 0x15
ASC_SYN		.equ 0x16
ASC_ETB		.equ 0x17
ASC_CAN		.equ 0x18
ASC_EM		.equ 0x19
ASC_SUB		.equ 0x1a
ASC_ESC		.equ 0x1b
ASC_FS		.equ 0x1c
ASC_GS		.equ 0x1d
ASC_RS		.equ 0x1e
ASC_US		.equ 0x1f
ASC_SP		.equ 0x20

; amiga 600 maxi09os special chars for function and cursor keys

ASC_F1		.equ 0x80
ASC_F2		.equ 0x81
ASC_F3		.equ 0x82
ASC_F4		.equ 0x83
ASC_F5		.equ 0x84
ASC_F6		.equ 0x85
ASC_F7		.equ 0x86
ASC_F8		.equ 0x87
ASC_F9		.equ 0x88
ASC_F10		.equ 0x89
ASC_HELP	.equ 0x8a
ASC_UP		.equ 0x8b
ASC_DOWN	.equ 0x8c
ASC_LEFT	.equ 0x8d
ASC_RIGHT	.equ 0x8e
ASC_DEL		.equ 0x8f

; special uart break emulation sequence

ASC_BREAK	.equ 0xff
