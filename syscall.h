#include <stddef.h>

// Syscall Marco
#define SYS_FORK        0x1
#define SYS_GETPID      0x2
#define SYS_WRITE       0x3
#define SYS_READ        0x4
#define SYS_INTERRUPT   0x5
#define SYS_GETPRIORITY 0x6
#define SYS_SETPRIORITY 0x7
#define SYS_MKNOD       0x8
#define SYS_SLEEP       0x9
#define SYS_SBRK        0xA

void *activate(void *stack);

int fork();
int getpid();

int write(int fd, const void *buf, size_t count);
int read(int fd, void *buf, size_t count);

void interrupt_wait(int intr);

int getpriority(int who);
int setpriority(int who, int value);

int mknod(int fd, int mode, int dev);

void sleep(unsigned int);

void *sbrk(unsigned increment);
