#define COMPAT_FREEBSD4 1
#define COMPAT_FREEBSD5 1
#define COMPAT_FREEBSD6 1
#define COMPAT_FREEBSD7 1
#define COMPAT_43 1

#include <sys/types.h>
#include <sys/param.h>
#include <sys/proc.h>
#include <sys/module.h>
#include <sys/sysent.h>
#include <sys/kernel.h>
#include <sys/systm.h>
#include <sys/syscall.h>
#include <sys/sysproto.h>
#include <sys/conf.h>

#include <kern/syscalls.c>
#include "syscalls.c"

/*
 * The function called at load/unload.
 */
static void compare_syscalls(void) {
  int error[SYS_MAXSYSCALL];

  bzero(&error, sizeof(error));
  check_syscalls(error);

  uprintf("- Modified System Calls -\n");
  uprintf("%-6s %-30s %s\n", "number", "name", "new-addr");
  uprintf("%-6s %-30s %s\n", "------", "---------", "--------");

  for (int counter = 0; counter < SYS_MAXSYSCALL; ++counter)
    if (error[counter])
      uprintf("%-6d %-30s %p\n", counter, syscallnames[counter], sysent[counter].sy_call);
  uprintf("- End -\n");
}

static int syscall_checker_handler(struct module *module, int cmd, void *arg) {
  int error = 0;

  switch (cmd) {
    case MOD_LOAD:
      /* Run check */
      compare_syscalls();
      break;
    case MOD_UNLOAD:
    case MOD_SHUTDOWN:
      break;
    default :
      error = EINVAL;
      break;
  }
  return error;
}

DEV_MODULE(syscall_checker, syscall_checker_handler, NULL);
MODULE_VERSION(syscall_checker, 1);
