		.include 'externs.inc'

; DEBUG related

.define DEBUG

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
;DEBUG_MODE	.equ DEBUG_GENERAL|DEBUG_TASK|DEBUG_INT
DEBUG_MODE	.equ DEBUG_ALL
.else
DEBUG_MODE	.equ 0
.endif
		
; list struct offsets

LIST_HEAD	.equ 0
LIST_TAIL	.equ 2
LIST_TAILPREV	.equ 4
LIST_SIZE	.equ 6

; node struct offsets

NODE_NEXT	.equ 0
NODE_PREV	.equ 2
NODE_SIZE	.equ 4

; a record describe a task in the system

TASK_NODE	.equ 0			; a node for this task
TASK_PC		.equ NODE_SIZE+0	; the initial program counter
TASK_SP		.equ NODE_SIZE+2	; the current stack pointer
TASK_SIGALLOC	.equ NODE_SIZE+4	; signal bits in use
TASK_SIGWAIT	.equ NODE_SIZE+5	; signal bits being waited on
TASK_SIGRECVD	.equ NODE_SIZE+6	; signal bits recieved
TASK_INTNEST	.equ NODE_SIZE+7	; interrupt nest count
TASK_PERMITNEST	.equ NODE_SIZE+8	; permit nest count
TASK_DISPCOUNT	.equ NODE_SIZE+9	; dispatch counter
TASK_NAME	.equ NODE_SIZE+11	; task name ("my task\0")
TASK_DEF_IO	.equ NODE_SIZE+19	; the default io device
TASK_PARENT	.equ NODE_SIZE+21	; the parent task
TASK_EXIT_CODE	.equ NODE_SIZE+23	; the exit code of this task
TASK_DEAD_LIST	.equ NODE_SIZE+24	; the list of dead children
TASK_SIZE	.equ NODE_SIZE+24+LIST_SIZE

; reserved signal masks

SIGNAL_CHILD	.equ 0x80		; child task has exited
SIGNAL_RESERVED	.equ SIGNAL_CHILD	; not available for tasks

; exit codes

EXIT_OK		.equ 0			; all ok
EXIT_ERROR	.equ 1			; generic failure code
EXIT_UNDEF	.equ 0xff		; task not exited yet

; a record describing an available driver

DRIVER_OPEN	.equ 0			; device open routine
DRIVER_PREPARE	.equ 2			; prepare a driver
DRIVER_NAME	.equ 4			; driver name ("uart\0")
DRIVER_SIZE	.equ 12

; an open device

DEVICE_NODE	.equ 0			; list node (unused currently)
DEVICE_CLOSE	.equ NODE_SIZE+0	; device close routine
DEVICE_READ	.equ NODE_SIZE+2	; read a byte into a
DEVICE_WRITE	.equ NODE_SIZE+4	; write a byte from a
DEVICE_CONTROL	.equ NODE_SIZE+6	; generic control method
DEVICE_TASK	.equ NODE_SIZE+8	; the task that opened the device
DEVICE_SIGNAL	.equ NODE_SIZE+10	; the signal bit for the device
DEVICE_SIZE	.equ NODE_SIZE+11

; stack frame offsets

STACK_CC	.equ 0
STACK_A		.equ 1
STACK_B		.equ 2
STACK_DP	.equ 3
STACK_X		.equ 4
STACK_Y		.equ 6
STACK_U		.equ 8
STACK_PC	.equ 10

; firq stack frame offsets

FSTACK_CC	.equ 0
FSTACK_PC	.equ 1

; timer device control (a register)

TIMERCMD_START	.equ 0
TIMERCMD_STOP	.equ 1

TIMERCTRL_REP	.equ 0			; repeating?
TIMERCTRL_END	.equ 1
TIMERCTRL_SIZE	.equ 3
