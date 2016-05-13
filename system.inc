; ascii constants

NULL            .equ 0x00
BS              .equ 0x08
CR              .equ 0x0d
LF              .equ 0x0a
SOH		.equ 0x01
ACK		.equ 0x06
NAK		.equ 0x15
EOT		.equ 0x04
SP		.equ 0x20

; task struct offsets

TASK_NEXT	.equ 0
TASK_PC		.equ 2
TASK_SP		.equ 4
TASK_SIGWAIT	.equ 6
TASK_SIGRECVD	.equ 7
TASK_SIZE	.equ 8

; the list of available drivers

DRIVER_OPEN	.equ 0
DRIVER_NAME	.equ 2
DRIVER_SIZE	.equ 10

; operations that can be performed on a open device

DEVICE_DRIVER	.equ 0
DEVICE_CLOSE	.equ 2
DEVICE_READ	.equ 4
DEVICE_WRITE	.equ 6
DEVICE_SIZE	.equ 8

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
