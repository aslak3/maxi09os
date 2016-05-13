; in ram, add our global variables

		.area RAM (ABS)

		.org 0

; interrupt handler table

interrupttable:	.rmb 2*INTCOUNT

; task switcher state

currenttask:	.rmb 2
readytasks:	.rmb 2
waitingtasks:	.rmb 2

idletask:	.rmb 2

task1save:	.rmb 2
task2save:	.rmb 2

; interrupt nest count, <=0 disabled, >0 enabled

interruptnest:	.rmb 1

