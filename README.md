# MAXI09OS

## Summary

MAXI09OS is an operating system for my MAXI09 8 bit 6809 SBC. It is very much a work in progress.  It is not another of those cut-down Unix available for the 6809, but rather it borrows ideas from a few different OSes and implements some of my own.  The principle reason this thing exists is for the fun in writing it, and as a means to learn about the mechanics of writing an 8 bit OS.

## Rough list of features

+ Simple single-link list based dynamic memory allocator
+ Objects are usually stored in a double-linked list, which uses the same dummy link in the list header as AmigaOS for speed
+ Preemptive task switching, simple round robin
+ Device driver model for IO abstraction
+ Interrupt usage is currently limited to UART port rx
+ Signal/Wait mechanism borrowed from AmigaOS but 8 bit signals
+ Drivers for...
  + SC16C654 QUAD UART
  + V9958 text-mode console, with 6 virtual consoles
  + Non repeating or repeating timers
  + Joystick ports
  + IDE block device
+ Debug monitor task
+ MinixFS file layer, read only
+ Startings of a simple command Shell

## TODO

+ Drivers for...
  + 6522 parallel printer port
  + SPI controller
    + Real Time Clock (DS1305)
    + Analogoue joysticks
    + SPI EEPROM
 + OPL2 (no idea how that will work yet)
+ Better terminal emulation in console driver
+ Write support for the Minix FS layer
+ More Shell commands
  + Date set and get with RTC
  + Copy file
  + Create directory
  + Etc..
+ Command redirection so files can be printed
+ Maybe write a basic full screen editor

## More info

If you want to learn more about this project, or the MAXI09 board, the best place to start is probably [my blog](http://aslak3.blogspot.co.uk).
