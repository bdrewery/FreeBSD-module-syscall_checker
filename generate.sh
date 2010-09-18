#! /bin/sh

cat > /dev/null << EOF
# From sys/kern/syscalls.master
types:
      STD     always included
      COMPAT  included on COMPAT #ifdef
      COMPAT4 included on COMPAT4 #ifdef (FreeBSD 4 compat)
      COMPAT6 included on COMPAT6 #ifdef (FreeBSD 6 compat)
      COMPAT7 included on COMPAT7 #ifdef (FreeBSD 7 compat)
      LIBCOMPAT included on COMPAT #ifdef, and placed in syscall.h
      OBSOL   obsolete, not included in system, only specifies name
      UNIMPL  not implemented, placeholder only
      NOSTD   implemented but as a lkm that can be statically
              compiled in; sysent entry will be filled with lkmressys
              so the SYSCALL_MODULE macro works
      NOARGS  same as STD except do not create structure in sys/sysproto.h
      NODEF   same as STD except only have the entry in the syscall table
              added.  Meaning - do not create structure or function
              prototype in sys/sysproto.h
      NOPROTO same as STD except do not create structure or
              function prototype in sys/sysproto.h.  Does add a
              definition to syscall.h besides adding a sysent.
EOF

cat << EOF
#include <sys/syscall.h>

static void check_syscalls(int* error) {
EOF


# STD/NOPROTO : xx
echo ""
printf "  /* STD system calls */\n"
awk '$1 ~ /^[0-9]/ && $2 ~ "AUE_.*" && ($3 == "STD" || $3 == "NOPROTO") {print $1 " " $6 }' /usr/src/sys/kern/syscalls.master |
  while read syscall proto; do
    printf "  if (sysent[%d].sy_call != (sy_call_t*) %s) error[%d] = 1;\n" $syscall ${proto%(*} $syscall
  done

# COMPAT : xx
echo ""
printf "  /* COMPAT system calls */\n"
awk '$1 ~ /^[0-9]/ && $2 ~ "AUE_.*" && ($3 == "COMPAT" || $3 ~ /\|COMPAT/) {print $1 " " $6 }' /usr/src/sys/kern/syscalls.master |
  while read syscall proto; do
    # FIXME: Check if COMPAT43 is enabled in kernel
    if [ 1 -eq 0 ]; then
      printf "  if (sysent[%d].sy_call != (sy_call_t*) o%s) error[%d] = 1;\n" $syscall ${proto%(*} $syscall
    else
      printf "  if (sysent[%d].sy_call != (sy_call_t*) nosys) error[%d] = 1;\n" $syscall $syscall
    fi
  done

# COMPAT4 : freebsd4_xx
echo ""
printf "  /* COMPAT4 system calls */\n"
awk '$1 ~ /^[0-9]/ && $2 ~ "AUE_.*" && $3 == "COMPAT4" {print $1 " " $6 }' /usr/src/sys/kern/syscalls.master |
  while read syscall proto; do
    if [ $(sysctl -qn kern.features.compat_freebsd4) -eq 1 ]; then
      printf "  if (sysent[%d].sy_call != (sy_call_t*) freebsd4_%s) error[%d] = 1;\n" $syscall ${proto%(*} $syscall
    else
      printf "  if (sysent[%d].sy_call != (sy_call_t*) nosys) error[%d] = 1;\n" $syscall $syscall
    fi
  done

# COMPAT6 : freebsd6_xx
echo ""
printf "  /* COMPAT6 system calls */\n"
awk '$1 ~ /^[0-9]/ && $2 ~ "AUE_.*" && $3 == "COMPAT6" {print $1 " " $6 }' /usr/src/sys/kern/syscalls.master |
  while read syscall proto; do
    if [ $(sysctl -qn kern.features.compat_freebsd6) -eq 1 ]; then
      printf "  if (sysent[%d].sy_call != (sy_call_t*) freebsd6_%s) error[%d] = 1;\n" $syscall ${proto%(*} $syscall
    else
      printf "  if (sysent[%d].sy_call != (sy_call_t*) nosys) error[%d] = 1;\n" $syscall $syscall
    fi
  done

# COMPAT7 : freebsd7
echo ""
printf "  /* COMPAT7 system calls */\n"
awk '$1 ~ /^[0-9]/ && $2 ~ "AUE_.*" && $3 ~ /COMPAT7/ {print $1 " " $6 }' /usr/src/sys/kern/syscalls.master |
  while read syscall proto; do
    if [ $(sysctl -qn kern.features.compat_freebsd7) -eq 1 ]; then
      printf "  if (sysent[%d].sy_call != (sy_call_t*) freebsd7%s) error[%d] = 1;\n" $syscall ${proto%(*} $syscall
    else
      printf "  if (sysent[%d].sy_call != (sy_call_t*) nosys) error[%d] = 1;\n" $syscall $syscall
    fi
  done

# OBSOL : nosys
echo ""
printf "  /* OBSOL/UNIMPL system calls */\n"
awk '$1 ~ /^[0-9]/ && $2 ~ "AUE_.*" && ($3 == "OBSOL" || $3 == "UNIMPL") {print $1}' /usr/src/sys/kern/syscalls.master |
  while read syscall; do
    printf "  if (sysent[%d].sy_call != (sy_call_t*) nosys) error[%d] = 1;\n" $syscall $syscall
  done

## NOSTD : These are diff - hackish. Either loaded or lkmressys
echo ""
printf "  /* NOSTD system calls */\n"
awk '$1 ~ /^[0-9]/ && $2 ~ "AUE_.*" && $3 == "NOSTD" {print $1 " " $6 }' /usr/src/sys/kern/syscalls.master |
  while read syscall proto; do

    mod_name=${proto%(*}
    if [ ! "${proto#ksem_*}" = "${proto}" ]; then
      mod_name="\<sem\>"
    elif [ "${proto%(*}" = "nfssvc" ]; then
      mod_name="\<nfsserver\>"
    elif [ "${proto%(*}" = "nlm_syscall" ]; then
      mod_name="\<nfslockd\>"
    fi

    if kldstat -v|grep "${mod_name}" > /dev/null 2>&1; then
      printf "  if (sysent[%d].sy_call != (sy_call_t*) %s) error[%d] = 1;\n" $syscall ${proto%(*} $syscall
    else
      printf "  if (sysent[%d].sy_call != (sy_call_t*) lkmressys) error[%d] = 1;\n" $syscall $syscall
    fi
  done

# NODEF : XX
echo ""
printf "  /* NODEF system calls */\n"
awk '$1 ~ /^[0-9]/ && $2 ~ "AUE_.*" && $3 == "NODEF" {print $1 " " $5}' /usr/src/sys/kern/syscalls.master |
  while read syscall sym; do
    printf "  if (sysent[%d].sy_call != (sy_call_t*) %s) error[%d] = 1;\n" $syscall $sym $syscall
  done

echo ""
printf "  /* Compat system calls */\n"

echo "}"
