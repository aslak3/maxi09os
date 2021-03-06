enable		 .equ 0xc000
disable		 .equ 0xc002
permit		 .equ 0xc004
forbid		 .equ 0xc006
sysopen		 .equ 0xc008
sysclose	 .equ 0xc00a
sysread		 .equ 0xc00c
syswrite	 .equ 0xc00e
sysseek		 .equ 0xc010
syscontrol	 .equ 0xc012
getnextdirent	 .equ 0xc014
opencwd		 .equ 0xc016
findinode	 .equ 0xc018
openfile	 .equ 0xc01a
closefile	 .equ 0xc01c
statfile	 .equ 0xc01e
statopenfile	 .equ 0xc020
typeopenfile	 .equ 0xc022
changecwd	 .equ 0xc024
initlist	 .equ 0xc026
addhead		 .equ 0xc028
addtail		 .equ 0xc02a
remhead		 .equ 0xc02c
remtail		 .equ 0xc02e
remove		 .equ 0xc030
memoryavail	 .equ 0xc032
memoryalloc	 .equ 0xc034
memoryfree	 .equ 0xc036
createtask	 .equ 0xc038
newtask		 .equ 0xc03a
exittask	 .equ 0xc03c
childexit	 .equ 0xc03e
runchild	 .equ 0xc040
settaskname	 .equ 0xc042
signalalloc	 .equ 0xc044
signalfree	 .equ 0xc046
wait		 .equ 0xc048
signal		 .equ 0xc04a
mountminix	 .equ 0xc04c
unmountminix	 .equ 0xc04e
readfsblock	 .equ 0xc050
getinode	 .equ 0xc052
handleioerror	 .equ 0xc054
getchardefio	 .equ 0xc056
getchar		 .equ 0xc058
putchardefio	 .equ 0xc05a
putchar		 .equ 0xc05c
getchars	 .equ 0xc05e
putstrdefio	 .equ 0xc060
putstr		 .equ 0xc062
getstrdefio	 .equ 0xc064
getstr		 .equ 0xc066
putbytedefio	 .equ 0xc068
putbyte		 .equ 0xc06a
putbytebdefio	 .equ 0xc06c
putbyteb	 .equ 0xc06e
putworddefio	 .equ 0xc070
putword		 .equ 0xc072
putlabwdefio	 .equ 0xc074
putlabw		 .equ 0xc076
putlabbdefio	 .equ 0xc078
putlabb		 .equ 0xc07a
putlabbbdefio	 .equ 0xc07c
putlabbb	 .equ 0xc07e
bytetoaschex	 .equ 0xc080
wordtoaschex	 .equ 0xc082
copystr		 .equ 0xc084
strcmp		 .equ 0xc086
parseinput	 .equ 0xc088
printableasc	 .equ 0xc08a
toupper		 .equ 0xc08c
strmatcharray	 .equ 0xc08e
vindirect	 .equ 0xc090
vsetcolour	 .equ 0xc092
vsetcolours	 .equ 0xc094
vinit		 .equ 0xc096
vwrite		 .equ 0xc098
vclear		 .equ 0xc09a
vread		 .equ 0xc09c
vseekwrite	 .equ 0xc09e
vseekread	 .equ 0xc0a0
geterrorstr	 .equ 0xc0a2
delay		 .equ 0xc0a4
swapword	 .equ 0xc0a6
swaplong	 .equ 0xc0a8
div32		 .equ 0xc0aa
mul32		 .equ 0xc0ac
memcpy256	 .equ 0xc0ae
putchars	 .equ 0xc0b0
aschextobyte	 .equ 0xc0b2
aschextoword	 .equ 0xc0b4
lengthopenfile	 .equ 0xc0b6
setgraphicsub	 .equ 0xc0b8
readfile	 .equ 0xc0ba
