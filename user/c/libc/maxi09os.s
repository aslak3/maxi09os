
;;; gcc for m6809 : Aug  6 2017 11:17:25
;;; 4.6.4 (gcc6809lw pl6b)
;;; ABI version 1
;;; -mint16
	.module	maxi09os.c
	.area .text
	.globl _m_putstr
_m_putstr:
	stx	,u
;----- asm -----
;  3 "maxi09os.c" 1
	ldy ,u
	jmp [0xc060]
	
;  0 "" 2
;--- end asm ---
	.globl _m_getstr
_m_getstr:
	stx	,u
;----- asm -----
;  12 "maxi09os.c" 1
	ldy ,u
	jmp [0xc064]
	
;  0 "" 2
;--- end asm ---
