		.include 'system.inc'
		.include 'hardware.inc'

; in ram, add our global variables

		.area RAM

; interrupt handler table

; task switcher state

currenttask::	.rmb 2			; current task pointer
defaultio::	.rmb 2			; current task's io channel

readytasks::	.rmb LIST_SIZE
waitingtasks::	.rmb LIST_SIZE

reschedflag::	.rmb 1

idletask::	.rmb 2

; interrupt nest count, <1 disabled, >=1 enabled

interruptnest::	.rmb 1
permitnest::	.rmb 1

; interrupt table - handlers

inthandlers::	.rmb INTPOSCOUNT*2
