		.include 'externs.inc'

; list struct offsets

LIST_HEAD	.equ 0
LIST_TAIL	.equ 2
LIST_TAILPREV	.equ 4
LIST_SIZE	.equ 6

; node struct offsets

NODE_NEXT	.equ 0
NODE_PREV	.equ 2
NODE_SIZE	.equ 4

; task struct offsets

TASK_NODE	.equ 0
TASK_PC		.equ NODE_SIZE+0	; the initial program counter
TASK_SP		.equ NODE_SIZE+2	; the current stack pointer
TASK_SIGALLOC	.equ NODE_SIZE+4	; signal bits in use
TASK_SIGWAIT	.equ NODE_SIZE+5	; signal bits being waited on
TASK_SIGRECVD	.equ NODE_SIZE+6	; signal bits recieved
TASK_INTNEST	.equ NODE_SIZE+7
TASK_PERMITNEST	.equ NODE_SIZE+8
TASK_DISPCOUNT	.equ NODE_SIZE+9
TASK_SIZE	.equ NODE_SIZE+11

; an element the list of available drivers

DRIVER_OPEN	.equ 0			; device open routine
DRIVER_PREPARE	.equ 2			; prepare a driver
DRIVER_NAME	.equ 4			; driver name ("uart\0")
DRIVER_SIZE	.equ 12

; operations that can be performed on a open device

DEVICE_NODE	.equ 0			; list node
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

TIMERCTRL_REP	.equ 0
TIMERCTRL_END	.equ 1
TIMERCTRL_SIZE	.equ 3
