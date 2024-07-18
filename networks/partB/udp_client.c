#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <fcntl.h>
#include <sys/time.h>

#define CHUNKSIZE 10

struct packet
{
    char data[1024];
    suseconds_t ctime;
    int seqno;
};

int main()
{
    int client_socket;
    struct sockaddr_in server_addr;
    socklen_t server_addr_len = sizeof(server_addr);
    char buffer[1024];

    // Create socket
    client_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (client_socket == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Initialize server address
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(8080);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    const char *message = "Hello, UDP Server! i am the client i will send you some data via udp protocol lets make sure the data is receiced properly";
    int nchunks;
    int len = strlen(message);
    if (len % CHUNKSIZE == 0)
    {
        nchunks = len / CHUNKSIZE;
    }
    else
    {
        nchunks = (len / CHUNKSIZE) + 1;
    }
    char str[1024];
    sprintf(str, "%d", nchunks);
    ssize_t bytes_sent = sendto(client_socket, str, strlen(str), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
    if (bytes_sent == -1)
    {
        perror("Sending data failed");
        close(client_socket);
        exit(1);
    }
    struct timeval curr_time;
    int i = 0;
    char ok[1024];
    struct packet pack[1024];
    int count = 0;
    int unack[nchunks];
    memset(unack, -1, sizeof(unack));
    ssize_t bytes_received;
    int no = 0;
    while ((no != nchunks) || count == 0)
    {
        struct packet paj;
        if (no < nchunks)
        {
            bzero(ok, 1024);
            strncpy(ok, message + (no * 10), 10);
            ok[strlen(ok)] = '\0';
            strcpy(pack[no].data, ok);
            pack[no].seqno = no;
            ssize_t bytes_sent = sendto(client_socket, &pack[no], sizeof(pack[no]), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
            printf("Sent data packet %d\n", pack[no].seqno);
            gettimeofday(&curr_time, NULL);
            time_t he = curr_time.tv_sec;
            pack[no].ctime = curr_time.tv_usec;
            bytes_received = recvfrom(client_socket, &paj, sizeof(paj), O_NONBLOCK, (struct sockaddr *)&server_addr, &server_addr_len);

            gettimeofday(&curr_time, NULL);

            int d = paj.seqno;

            if (bytes_received > 0 && unack[d] != 0)
            {
                // printf("curr_time: %ld\ncurr_ti: %ld\ncurr: %ld\nentry : %ld\n", he, curr_time.tv_sec, curr_time.tv_usec, pack[d].ctime);
                // printf("TIME: %ld\n", (curr_time.tv_usec - pack[d].ctime));
            }
            if (bytes_received > 0 && unack[d] != 0 && (curr_time.tv_usec - pack[d].ctime) > 100000)
            {
                count++;
                unack[d] = 1;
                for (int j = 0; j < nchunks; j++)
                {
                    if (unack[j] == 1)
                    {
                        printf("Retransmittinng data chunk %d\n", j);
                        bytes_sent = sendto(client_socket, &pack[j], sizeof(pack[j]), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
                        printf("Sent data packet %d\n", pack[j].seqno);
                        gettimeofday(&curr_time, NULL);
                        pack[j].ctime = curr_time.tv_usec;
                        bzero(&paj, sizeof(struct packet));
                        bytes_received = recvfrom(client_socket, &paj, sizeof(paj), O_NONBLOCK, (struct sockaddr *)&server_addr, &server_addr_len);
                        d = paj.seqno;
                        gettimeofday(&curr_time, NULL);
                        if (bytes_received > 0 && curr_time.tv_usec - pack[d].ctime <= 100000)
                        {
                            no++;
                            printf("Received acknowledgement for chunk %d\n", d);
                            count--;
                            unack[d] = 0;
                        }
                    }
                }
            }
            else if (bytes_received > 0 && unack[d] != 0)
            {
                unack[d] = 0;
                no++;
                printf("Received acknowledgement for chunk %d\n", d);
            }
        }
        else if (no >= nchunks)
        {
            if (count == 0)
            {
                break;
            }
            else
            {
                for (int j = 0; j < nchunks; j++)
                {
                    if (unack[j] == 1)
                    {
                        printf("Retransmittinng data chunk %d\n", j);
                        bytes_sent = sendto(client_socket, &pack[j], sizeof(pack[j]), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
                        printf("Sent data packet %d\n", pack[j].seqno);
                        gettimeofday(&curr_time, NULL);
                        pack[j].ctime = curr_time.tv_usec;
                        bzero(&paj, sizeof(struct packet));
                        bytes_received = recvfrom(client_socket, &paj, sizeof(paj), O_NONBLOCK, (struct sockaddr *)&server_addr, &server_addr_len);
                        int d = paj.seqno;
                        gettimeofday(&curr_time, NULL);
                        if (bytes_received > 0 && unack[d] != 0 && curr_time.tv_usec - pack[d].ctime <= 100000)
                        {
                            no++;
                            printf("Received acknowledgement for chunk %d\n", d);
                            count--;
                            unack[d] = 0;
                        }
                    }
                }
            }
        }

        i++;
    }
    struct packet pat;
    pat.ctime = 0;
    strcpy(pat.data, "##");
    pat.seqno = -1;
    bytes_sent = sendto(client_socket, &pat, sizeof(pat), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
    char arr[1024];
    bytes_received = recvfrom(client_socket, arr, sizeof(arr), 0, (struct sockaddr *)&server_addr, &server_addr_len);
    int y = 0;
    if (bytes_received > 0)
    {
        y = atoi(arr);
    }
    char hoo[1024];
    struct packet patr;
    struct packet packt[y];
    int receive[1024];
    memset(receive, -1, sizeof(receive));
    i = 0;
    memset(packt, 0, sizeof(packt));
    while (1)
    {
        bzero(&patr, sizeof(patr));
        bytes_received = recvfrom(client_socket, &patr, sizeof(patr), 0, (struct sockaddr *)&server_addr, &server_addr_len);
        if (strcmp(patr.data, "##") == 0)
        {
            // printf("%s",patr.data);
            break;
        }
        receive[patr.seqno] = 1;
        packt[patr.seqno].seqno = patr.seqno;
        strcpy(packt[patr.seqno].data, patr.data);
        packt[patr.seqno].ctime = 0;
        if (bytes_received > 0 && receive[patr.seqno] == -1)
        {
            printf("Received data chunk: %d\n", packt[patr.seqno].seqno);
        }
        // if (i % 3 == 0)
        // {
        //     usleep(100000);
        // }
        // char str[1024];
        // sprintf(str, "%d", patr.seqno);
        struct packet paj;
        paj.ctime = 0;
        paj.seqno = patr.seqno;
        strcpy(paj.data, patr.data);
        bytes_sent = sendto(client_socket, &paj, sizeof(paj), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
        if (bytes_sent > 0)
        {
            printf("sent acknowledgement for data chunk %d\n", paj.seqno);
        }
        i++;
    }
    memset(hoo, 0, sizeof(hoo));
    for (int i = 0; i < y; i++)
    {
        strcat(hoo, packt[i].data);
    }
    printf("TEXT: %s\n", hoo);

    close(client_socket);

    return 0;
}
