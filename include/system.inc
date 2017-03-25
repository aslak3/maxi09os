		.include 'externs.inc'

; DEBUG related

;.define DEBUG

DEBUG_GENERAL	.equ 0x01
DEBUG_TASK	.equ 0x02
DEBUG_ENDDIS	.equ 0x04
DEBUG_INT	.equ 0x08
DEBUG_MEMORY	.equ 0x10
DEBUG_DRIVER	.equ 0x20
DEBUG_SPEC_DRV	.equ 0x40
DEBUG_ALL	.equ 0xff

DEBUG_REG_A	.equ 0x01
DEBUG_REG_B	.equ 0x02
DEBUG_REG_X	.equ 0x04
DEBUG_REG_Y	.equ 0x08

.ifdef DEBUG
.msg 'Debug is enabled'
;DEBUG_MODE	.equ DEBUG_MEMORY|DEBUG_TASK
DEBUG_MODE	.equ 0xff
.else
DEBUG_MODE	.equ 0
.endif

; structure macros

.macro structstart offset
structrunning=offset
.endm

.macro member lab,offset
lab .equ structrunning
structrunning=structrunning+offset
.endm

.macro structend lab
lab .equ structrunning
.endm
		
; list struct offsets

structstart	0
member		LIST_HEAD,2
member		LIST_TAIL,2
member		LIST_TAILPREV,2
structend	LIST_SIZE

; node struct offsets

structstart 	0
member		NODE_NEXT,2
member		NODE_PREV,2
structend	NODE_SIZE

; flags for memoryavail

MEM_TOTAL	.equ 0
MEM_FREE	.equ 1
MEM_LARGEST	.equ 2

; a record describe a task in the system

structstart	NODE_SIZE		; a node for this task
member		TASK_PC,2		; the initial program counter
member		TASK_SP,2		; the current stack pointer
member		TASK_SIGALLOC,1		; signal bits in use
member		TASK_SIGWAIT,1		; signal bits being waited on
member		TASK_SIGRECVD,1		; signal bits recieved
member		TASK_INTNEST,1		; interrupt nest count
member		TASK_PERMITNEST,1	; permit nest count
member		TASK_DISPCOUNT,2	; dispatch counter
member		TASK_NAME,8		; task name ("my task\0")
member		TASK_DEF_IO,2		; the default io device
member		TASK_PARENT,2		; the parent task
member		TASK_EXIT_CODE,1	; the exit code of this task
member		TASK_DEAD_LIST,LIST_SIZE; the list of dead children
member		TASK_CWD_INODENO,2	; current working dir
structend	TASK_SIZE

; reserved signal masks

SIGNAL_CHILD	.equ 0x80		; child task has exited
SIGNAL_RESERVED	.equ SIGNAL_CHILD	; not available for tasks

; exit codes

EXIT_OK		.equ 0			; all ok
EXIT_ERROR	.equ 1			; generic failure code
EXIT_UNDEF	.equ 0xff		; task not exited yet

; a record describing an available driver

structstart	0
member		DRIVER_OPEN,2		; device open routine
member		DRIVER_PREPARE,2	; prepare a driver
member		DRIVER_NAME,8		; driver name ("uart\0")
structend	DRIVER_SIZE

; an open device

structstart	NODE_SIZE		; list node (unused currently)
member		DEVICE_CLOSE,2		; device close routine
member		DEVICE_READ,2		; read a byte into a
member		DEVICE_WRITE,2		; write a byte from a
member		DEVICE_SEEK,2		; seek to position y
member		DEVICE_CONTROL,2	; generic control method
member		DEVICE_TASK,2		; the task that opened the device
member		DEVICE_SIGNAL,1		; the signal bit for the device
structend	DEVICE_SIZE

; stack frame offsets

structstart	0
member		STACK_CC,1
member		STACK_A,1
member		STACK_B,1
member		STACK_DP,1
member		STACK_X,2
member		STACK_Y,2
member		STACK_U,2
member		STACK_PC,2

; firq stack frame offsets

structstart	0
member		FSTACK_CC,1
member		FSTACK_PC,2

; timer device control (a register)

TIMERCMD_START	.equ 0
TIMERCMD_STOP	.equ 1

TIMERCTRL_REP	.equ 0			; repeating?
TIMERCTRL_END	.equ 1
TIMERCTRL_SIZE	.equ 3

; ide device control (a register)

IDECMD_IDENTIFY	.equ 0
IDECMD_READ_MBR	.equ 1

; macros for twiddling with condition code

.macro		enableinterrupts
		andcc #0xaf
.endm
.macro		disableinterrupts
		orcc #0x50
.endm

.macro		setnotzero
		andcc #0xfb
.endm
.macro		setzero
		orcc #0x04
.endm

.macro		setnotcarry
		andcc #0xfe
.endm

.macro		setcarry
		orcc #0x01
.endm