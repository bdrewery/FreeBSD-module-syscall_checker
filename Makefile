# Declare Name of kernel module
KMOD    =  syscall_checker

# Enumerate Source files for kernel module
SRCS    =  syscall_checker.c

CLEANFILES = syscalls.c

syscall_checker.c: syscalls.c
syscalls.c:
	./generate.sh > syscalls.c

# Include kernel module makefile
.include <bsd.kmod.mk>

