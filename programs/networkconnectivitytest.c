#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <stdbool.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

static bool checkNetworkConnectivity(void) {
    int sock = socket(AF_INET6, SOCK_DGRAM | SOCK_CLOEXEC, IPPROTO_UDP);
    bool ret = false;
    if (sock >= 0) {
        struct sockaddr_in6 server6 = {0};
        server6.sin6_family = AF_INET6;
        /* it's for 2000:: */
        server6.sin6_addr.s6_addr[0] = 0x20;

        if (connect(sock, (struct sockaddr *)&server6, sizeof(server6)) == 0) {
            close(sock);
            ret = true;
        }
        close(sock);
    }

    sock = socket(AF_INET, SOCK_DGRAM | SOCK_CLOEXEC, IPPROTO_UDP);
    if (sock < 0) {
	printf("Err\n");
	ret = false;
    }

    struct sockaddr_in server4 = {0};
    server4.sin_family = AF_INET;
    server4.sin_addr.s_addr = htonl(0x08080808); /* 8.8.8.8 */

    bool ok = (connect(sock, (struct sockaddr *)&server4, sizeof(server4)) == 0);
    close(sock);
    return ret;
}

int main(void) {
    bool online = checkNetworkConnectivity();
    printf("Network connectivity: %s\n", online ? "OK" : "FAIL");
    return online ? 0 : 1;
}
