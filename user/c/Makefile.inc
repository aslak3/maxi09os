#TOOLCHAIN = gcc
TOOLCHAIN = cmoc

ifeq ($(TOOLCHAIN), gcc)
CC = m6809-unknown-gcc
LD = m6809-unknown-ld
AR = m6809-unknown-ar

CFLAGS = -O2 -Wall -std=gnu99 -fPIC -I../libc/ -I../libmaxi09os/
else ifeq ($(TOOLCHAIN), cmoc)
CC = cmoc
LD = cmoc
#LD = lwlink
AR = lwar

CFLAGS = -Dconst= -Dvolatile= -O2 -I../libc/ -I../libmaxi09os/
else
$(error TOOLCHAIN not valid)
endif

%.o : %.c
	$(CC) $(CFLAGS) -c $<
