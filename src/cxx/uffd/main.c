#define _GNU_SOURCE
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <linux/userfaultfd.h>
#include <poll.h>
#include <pthread.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/syscall.h>
#include <sys/types.h>
#include <unistd.h>

#define barf(msg)                                                              \
  do {                                                                         \
    perror(msg);                                                               \
    exit(EXIT_FAILURE);                                                        \
  } while (0)

static int page_size;

static void* fault_handler_thread(void* arg) {
    long uffd;                  /* userfaultfd file descriptor */
    uffd = (long) arg;

    /* Loop, handling incoming events on the userfaultfd
       file descriptor. */

    for (;;) {
        /* See what poll() tells us about the userfaultfd. */

        struct pollfd pollfd;
        int nready;
        pollfd.fd = uffd;
        pollfd.events = POLLIN;
        nready = poll(&pollfd, 1, -1);
        if (nready == -1)
            barf("poll");

        printf("\nfault_handler_thread():\n");
        printf(
            "    poll() returns: nready = %d; "
            "POLLIN = %d; POLLERR = %d\n",
            nready, (pollfd.revents & POLLIN) != 0,
            (pollfd.revents & POLLERR) != 0);

        // received fault, exit the program
        exit(EXIT_FAILURE);
    }
}

int main(int argc, char *argv[]) {
  long uffd;     /* userfaultfd file descriptor */
  char *addr;    /* Start of region handled by userfaultfd */
  uint64_t len;  /* Length of region handled by userfaultfd */
  pthread_t thr; /* ID of thread that handles page faults */
  struct uffdio_api uffdio_api;
  struct uffdio_register uffdio_register;
  struct uffdio_writeprotect uffdio_wp;
  int s;

  page_size = sysconf(_SC_PAGE_SIZE);
  len = page_size;

  uffd = syscall(__NR_userfaultfd, O_CLOEXEC | O_NONBLOCK);
  if (uffd == -1)
    barf("userfaultfd");

  uffdio_api.api = UFFD_API;
  uffdio_api.features = UFFD_FEATURE_PAGEFAULT_FLAG_WP;
  uffdio_api.ioctls = 0;
  if (ioctl(uffd, UFFDIO_API, &uffdio_api) == -1)
    barf("ioctl(UFFDIO_API)");

  if (!(uffdio_api.features & UFFD_FEATURE_PAGEFAULT_FLAG_WP)) {
    printf("UFFD_FEATURE_PAGEFAULT_FLAG_WP is unavailable\n");
    exit(EXIT_FAILURE);
  }
  /* Create a private anonymous mapping. The memory will be
     demand-zero paged--that is, not yet allocated. When we
     actually touch the memory, it will be allocated via
     the userfaultfd. */
  addr = mmap(NULL, len, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS,
              -1, 0);
  if (addr == MAP_FAILED)
    barf("mmap");

  printf("Address returned by mmap() = %p\n", addr);

  /* Register the memory range of the mapping we just created for
     handling by the userfaultfd object. */

  uffdio_register.range.start = (unsigned long)addr;
  uffdio_register.range.len = len;
  uffdio_register.mode = UFFDIO_REGISTER_MODE_WP;
  if (ioctl(uffd, UFFDIO_REGISTER, &uffdio_register) == -1)
    barf("ioctl-UFFDIO_REGISTER");

  printf("uffdio_register.ioctls = 0x%llx\n", uffdio_register.ioctls);
  printf("Have _UFFDIO_WRITEPROTECT? %s\n",
         (uffdio_register.ioctls & _UFFDIO_WRITEPROTECT) ? "YES" : "NO");

  for (size_t i = 0; i < len; i += page_size) {
    addr[i] = 0;
  }

  uffdio_wp.range.start = (unsigned long)addr;
  uffdio_wp.range.len = len;
  uffdio_wp.mode = UFFDIO_WRITEPROTECT_MODE_WP;
  if (ioctl(uffd, UFFDIO_WRITEPROTECT, &uffdio_wp) == -1)
    barf("ioctl-UFFDIO_WRITEPROTECT");

  /* Create a thread that will process the userfaultfd events. */

  s = pthread_create(&thr, NULL, fault_handler_thread, (void *)uffd);
  if (s != 0) {
    errno = s;
    barf("pthread_create");
  }

  /* Main thread now touches memory in the mapping, touching
     locations 1024 bytes apart. This will trigger userfaultfd
     events for all pages in the region. */

  usleep(100000);

  size_t l;
  l = 0xf; /* Ensure that faulting address is not on a page
              boundary, in order to test that we correctly
              handle that case in fault_handling_thread(). */
  char i = 0;
  while (l < len) {
    printf("Write address %p in main(): ", addr + l);
    addr[l] = i++;
    printf("%d\n", addr[l]);
    l += 1024;
    usleep(100000); /* Slow things down a little */
  }

  exit(EXIT_SUCCESS);
}
