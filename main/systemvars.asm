		.include 'include/system.inc'
		.include 'include/hardware.inc'

; in ram, add our global variables

		.area RAM

; task switcher state

currenttask::	.rmb 2			; current task pointer
defaultio::	.rmb 2			; current task's io channel

readytasks::	.rmb LIST_SIZE		; tasks that have or want cpu
waitingtasks::	.rmb LIST_SIZE		; tasks that are wait()ing

idletask::	.rmb 2			; the idle task's handle

reschedflag::	.rmb 1			; int handler needs to schedule

; filesystem related

rootsuperblock::.rmb 2			; system-wide mounted superblock

; interrupt and permit nest counts, <1 disabled, >=1 enabled

interruptnest::	.rmb 1			; interrupts enabled?
permitnest::	.rmb 1			; task switching enabled?

; interrupt table - handlers

inthandlers::	.rmb INTPOSCOUNT*2
