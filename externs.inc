; console.asm

		.globl consoledef
		.globl conrxhandler

; driver.asm

		.globl driverprepare
		.globl sysopen
		.globl sysclosedefio
		.globl sysclose
		.globl sysreaddefio
		.globl sysread
		.globl syswritedefio
		.globl syswrite
		.globl sysctrldefio
		.globl sysctrl
		.globl driversignal

; fontdata.asm

		.globl fontdata

; init.asm

		.globl init

; io.asm

		.globl putstrdefio
		.globl putstr
		.globl getstrdefio
		.globl getstr
		.globl putbytedefio
		.globl putbyte
		.globl putworddefio
		.globl putword

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
		.globl newlinez
		.globl spacez

; memory.asm

		.globl memoryinit
		.globl memoryalloc
		.globl memoryfree

; misc.asm

		.globl delay
		.globl wordswap
		.globl div32
		.globl mul32

; monitor.asm

		.globl monitorstart

; scancodes.asm

		.globl mapscancode

; strings.asm

		.globl nibtoaschex
		.globl bytetoaschex
		.globl wordtoaschex
		.globl copystr
		.globl strcmp
		.globl parseinput
		.globl printableasc
		.globl toupper

; systemvars.asm

		.globl currenttask
		.globl defaultio
		.globl readytasks
		.globl waitingtasks
		.globl reschedflag
		.globl idletask
		.globl interruptnest
		.globl permitnest
		.globl inthandlers

; tasks.asm

		.globl createtask
		.globl newtask
		.globl exittask
		.globl childexit
		.globl settaskname
		.globl addtaskto
		.globl remtaskfrom
		.globl remtask
		.globl signalalloc
		.globl wait
		.globl signal
		.globl intsignal
		.globl tickerhandler
		.globl yield
		.globl doneschedule
		.globl idler

; testtasks.asm

		.globl timertask
		.globl echotask
		.globl sertermtask

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

