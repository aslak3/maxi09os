; tasks/testtasks.asm

		.globl timertask
		.globl echotask
		.globl sertermtask

; tasks/init.asm

		.globl init

; tasks/monitor.asm

		.globl monitorstart

; drivers/uart.asm

		.globl uartdef
		.globl uartrxhandler

; drivers/shared/uartlowlevel.asm

		.globl uartllopen
		.globl uartllclose
		.globl uartllsetbaud
		.globl uartllsethwhs
		.globl uartllhandler

; drivers/timer.asm

		.globl timerdef
		.globl runtimers

; drivers/ide.asm

		.globl idedef

; drivers/console/console.asm

		.globl consoledef
		.globl conrxhandler

; drivers/console/fontdata.asm

		.globl fontdata

; drivers/console/scancodes.asm

		.globl mapscancode

; drivers/driver.asm

		.globl driverprepare
		.globl sysopen
		.globl sysclose
		.globl sysread
		.globl syswrite
		.globl sysseek
		.globl sysctrl
		.globl driversignal
		.globl devicenotimpl

; drivers/led.asm

		.globl leddef

; misc/misc.asm

		.globl delay
		.globl wordswap
		.globl div32
		.globl mul32

; executive/lists.asm

		.globl initlist
		.globl addhead
		.globl addtail
		.globl remhead
		.globl remtail
		.globl remove

; executive/tasks.asm

		.globl createtask
		.globl newtask
		.globl exittask
		.globl childexit
		.globl runchild
		.globl settaskname
		.globl addtaskto
		.globl remtaskfrom
		.globl remtask
		.globl signalalloc
		.globl signalfree
		.globl wait
		.globl signal
		.globl intsignal
		.globl tickerhandler
		.globl yield
		.globl doneschedule
		.globl idler

; executive/ticker.asm

		.globl tickerinit

; executive/systemvars.asm

		.globl currenttask
		.globl defaultio
		.globl readytasks
		.globl waitingtasks
		.globl reschedflag
		.globl idletask
		.globl interruptnest
		.globl permitnest
		.globl inthandlers

; executive/memory.asm

		.globl memoryinit
		.globl memoryavail
		.globl memoryalloc
		.globl memoryfree

; executive/main.asm

		.globl enable
		.globl disable
		.globl permit
		.globl forbid
		.globl tailhandler
		.globl newlinemsg
		.globl newlinez
		.globl spacez

; lib/strings.asm

		.globl nibtoaschex
		.globl bytetoaschex
		.globl wordtoaschex
		.globl copystr
		.globl strcmp
		.globl parseinput
		.globl printableasc
		.globl toupper

; lib/v99lowlevel.asm

		.globl vindirect
		.globl vsetcolour
		.globl vsetcolours
		.globl vinit
		.globl vwrite
		.globl vclear
		.globl vread
		.globl vseekwrite
		.globl vseekread

; lib/io.asm

		.globl putstrdefio
		.globl putstr
		.globl getstrdefio
		.globl getstr
		.globl putbytedefio
		.globl putbyte
		.globl putbytebdefio
		.globl putbyteb
		.globl putworddefio
		.globl putword
		.globl putlabwdefio
		.globl putlabw
		.globl putlabbdefio
		.globl putlabb
		.globl putlabbbdefio
		.globl putlabbb

