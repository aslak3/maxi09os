; console.asm

		.globl consoledef
		.globl conrxhandler

; debug.asm

		.globl debuginit
		.globl debugprint
		.globl debugprintx
		.globl debugprinty
		.globl debugprinta
		.globl debugprintb

; driver.asm

		.globl driverprepare
		.globl sysopen
		.globl sysclose
		.globl sysread
		.globl syswrite
		.globl syscontrol
		.globl driversignal

; fontdata.asm

		.globl fontdata

; init.asm

		.globl init

; io.asm

		.globl putstr
		.globl getstr

; led.asm

		.globl leddef

; lists.asm

		.globl initlist
		.globl addhead
		.globl addtail
		.globl remhead
		.globl remtail
		.globl remove

; main.asm

		.globl enable
		.globl disable
		.globl permit
		.globl forbid
		.globl tailhandler
		.globl newlinemsg

; memory.asm

		.globl memoryinit
		.globl memoryalloc
		.globl memoryfree

; misc.asm

		.globl delay
		.globl wordswap
		.globl div32
		.globl mul32

; scancodes.asm

		.globl mapscancode

; strings.asm

		.globl bytetoaschex
		.globl wordtoaschex
		.globl concatstr
		.globl concatstrn
		.globl strcmp

; systemvars.asm

		.globl currenttask
		.globl readytasks
		.globl waitingtasks
		.globl rescheduleflag
		.globl idletask
		.globl interruptnest
		.globl permitnest
		.globl inthandlers

; tasks.asm

		.globl createtask
		.globl addtaskto
		.globl remtask
		.globl signalalloc
		.globl wait
		.globl signal
		.globl intsignal
		.globl tickerhandler
		.globl yield
		.globl finishschedule
		.globl idler

; testtasks.asm

		.globl task1
		.globl task2
		.globl task3
		.globl task4
		.globl task5

; ticker.asm

		.globl tickerinit

; timer.asm

		.globl timerdef
		.globl runtimers

; uart.asm

		.globl uartdef
		.globl uartrxhandler

; uartlowlevel.asm

		.globl uartllopen
		.globl uartllclose
		.globl uartllsetbaud
		.globl uartllsethwhs
		.globl uartllhandler

; v99lowlevel.asm

		.globl vindirect
		.globl vsetcolour
		.globl vsetcolours
		.globl vinit
		.globl vwrite
		.globl vclear
		.globl vread
		.globl vseekwrite
		.globl vseekread

