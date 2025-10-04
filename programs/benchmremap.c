#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <string.h>
#include <time.h>
#include <errno.h>

#define ONE_GB (1UL << 30)

static long get_time_ns() {
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return ts.tv_sec * 1000000000L + ts.tv_nsec;
}

int main() {
    size_t size = ONE_GB;
    void *addr = mmap(NULL, size, PROT_READ | PROT_WRITE,
                      MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (addr == MAP_FAILED) {
        perror("mmap");
        return 1;
    }

    // Touch the memory to ensure it’s mapped in RAM
    memset(addr, 1, size);

    long start = get_time_ns();
    void *new_addr = mremap(addr, size, size, MREMAP_MAYMOVE);
    long end = get_time_ns();

    if (new_addr == MAP_FAILED) {
        perror("mremap");
        return 1;
    }

    printf("Total mremap time for 1GB data: %ld nanoseconds.\n", end - start);

    // Clean up
    munmap(new_addr, size);
    return 0;
}
