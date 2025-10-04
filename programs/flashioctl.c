#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include "include/uapi/misc/mediatek/flashlight.h" // Just point it towards the header in your kernel

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Usage: %s <0|1> <1-6>\n", argv[0]);
        return 1;
    }

    int onoff = atoi(argv[1]);
    int duty = atoi(argv[2]);

    if (onoff != 0 && onoff != 1) {
        fprintf(stderr, "Invalid onoff. Use 0 (off) or 1 (on).\n");
        return 1;
    }

    if (duty < 1 && duty > 6) {
        fprintf(stderr, "Invalid duty. Use 1 through 6 for duty level.\n");
        return 1;
    }

    int fd = open("/dev/flashlight", O_RDWR);
    if (fd < 0) {
        perror("open");
        return 1;
    }

    struct flashlight_user_arg fl;

    fl.type_id = 1;
    fl.ct_id = 1;

    fl.arg = duty;
    ioctl(fd, FLASH_IOC_SET_DUTY, &fl);

    fl.arg = 0;
    ioctl(fd, FLASH_IOC_SET_TIME_OUT_TIME_MS, &fl);

    fl.arg = onoff;
    int ret = ioctl(fd, FLASH_IOC_SET_ONOFF, &fl);

    ret = ioctl(fd, FLASH_IOC_GET_CURRENT_TORCH_DUTY, &fl);
    if (ret == -1) {
        perror("ioctl");
    } else {
        printf("Torch duty = %d\n", fl.arg);
    }

    close(fd);
    return 0;
}
