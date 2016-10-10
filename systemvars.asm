		.include 'system.inc'
		.include 'hardware.inc'

; in ram, add our global variables

		.area RAM

; interrupt handler table

interrupttable::	.rmb 2*INTCOUNT

; task switcher state

currenttask::	.rmb 2

readytasks::	.rmb LIST_SIZE
waitingtasks::	.rmb LIST_SIZE

rescheduleflag::	.rmb 1

idletask::	.rmb 2

; interrupt nest count, <1 disabled, >=1 enabled

interruptnest::	.rmb 1
permitnest::	.rmb 1

; interrupt table - handlers

inthandlers::	.rmb 8*2

; interrupt table - masks

intmasks::	.rmb 8
