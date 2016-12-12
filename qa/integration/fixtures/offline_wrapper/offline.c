#include <linux/seccomp.h>
#include <linux/filter.h>
#include <sys/syscall.h>
#include <stddef.h>
#include <sys/types.h>
#include <errno.h>
#include <stdio.h>
#include <sys/prctl.h>
#include <unistd.h>

#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>

struct sock_filter reject_connect_and_bind[] = {
  // LD|W|ABS == Load Word at ABSolute offset
  // Load the syscall number
  BPF_STMT(BPF_LD|BPF_W|BPF_ABS, (offsetof(struct seccomp_data, nr))),

  // JMP|JEQ|K Do a jump after comparing EQuality of the loaded value and a
  // constant. If equal, jump 2 positions forward, if not equal, do not jump(zero jump).
  // Is it the `connect` syscall?
  BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K, __NR_connect, 2, 0),
  // Is it the `bind` syscall?
  BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K, __NR_bind, 1, 0),

  // RET|K Return a constant.
  // Neither bind nor connect? Allow it.
  BPF_STMT(BPF_RET|BPF_K, SECCOMP_RET_ALLOW),

  // Fun fact. `connect` and `bind` take the same arguments, so we can process them the same way.
  // int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen)
  // int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen)

  // Ideally, we'd load the 2nd arg (sockaddr struct) and look at the `sa_family` member to see
  // what kind of socket address is to be used. However, BPF/seccomp doesn't allow you to 
  // dereference pointers... so let's try relying on the sockaddr_len argument.

  // Load third argument to the syscall (addrlen)
  BPF_STMT(BPF_LD|BPF_W|BPF_ABS, offsetof(struct seccomp_data, args[2])),

  // Try filtering based on the sockaddr len. This isn't great, but may be better than nothing.
  //   - Reject sockaddr_in and sockaddr_in6
  //   - Allow everything else (unix sockets, etc)
  BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K, sizeof(struct sockaddr_in), 1, 0),
  BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K, sizeof(struct sockaddr_in6), 0, 1),
  BPF_STMT(BPF_RET|BPF_K, SECCOMP_RET_ERRNO|(EACCES&SECCOMP_RET_DATA)),
  BPF_STMT(BPF_RET|BPF_K, SECCOMP_RET_ALLOW),
};

struct sock_filter reject_inet_socket[] = {
  // LD|W|ABS == Load Word at ABSolute offset
  // Load the syscall number
  BPF_STMT(BPF_LD|BPF_W|BPF_ABS, (offsetof(struct seccomp_data, nr))),

  // Is it the `socket` syscall?
  BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K, __NR_socket, 1, 0),
  // Not `socket` call? Allow it.
  BPF_STMT(BPF_RET|BPF_K, SECCOMP_RET_ALLOW),

  // Load first argument to the syscall (domain)
  BPF_STMT(BPF_LD|BPF_W|BPF_ABS, offsetof(struct seccomp_data, args[0])),

  // Reject INET and INET6
  BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K, AF_INET, 1, 0),
  BPF_JUMP(BPF_JMP|BPF_JEQ|BPF_K, AF_INET6, 0, 1),
  BPF_STMT(BPF_RET|BPF_K, SECCOMP_RET_ERRNO|(EACCES&SECCOMP_RET_DATA)),
  BPF_STMT(BPF_RET|BPF_K, SECCOMP_RET_ALLOW),
};

int main(int argc, char **argv) {
  struct sock_filter *filter = reject_inet_socket;
  unsigned short count = sizeof(reject_inet_socket) / sizeof(filter[0]);

  struct sock_fprog prog = {
    .len = count,
    .filter = filter,
  };

  if (prctl(PR_SET_NO_NEW_PRIVS, 1, 0, 0, 0)) {
    perror("seccomp PR_SET_NO_NEW_PRIVS");
    return 1;
  }

  if (prctl(PR_SET_SECCOMP, SECCOMP_MODE_FILTER, &prog)) {
    perror("seccomp");
    return 1;
  }

  if (argc == 1) {
    printf("Usage: %s <program> [args]\n", argv[0]);
    return 1;
  }

  argv++;
  execvp(argv[0], argv);
  return 0;
}
