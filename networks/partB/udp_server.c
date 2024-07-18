#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <sys/time.h>
#include "fcntl.h"

#define CHUNKSIZE 10

struct packet
{
    char data[1024];
    suseconds_t ctime;
    int seqno;
};

int main()
{
    int server_socket;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_addr_len = sizeof(client_addr);
    char buffer[1024];

    // Create socket
    server_socket = socket(AF_INET, SOCK_DGRAM, 0);
    if (server_socket == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Initialize server address
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(8080);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket
    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Binding failed");
        close(server_socket);
        exit(1);
    }

    ssize_t bytes_received = recvfrom(server_socket, buffer, sizeof(buffer), 0, (struct sockaddr *)&client_addr, &client_addr_len);
    buffer[bytes_received] = '\0';
    int y = atoi(buffer);
    char hoo[1024];
    struct packet pat;
    struct packet pack[y];
    int i = 0, flag = 0;
    int receive[1024];
    memset(receive, -1, sizeof(receive));
    while (1)
    {
        bzero(&pat, sizeof(pat));
        ssize_t bytes_received = recvfrom(server_socket, &pat, sizeof(pat), 0, (struct sockaddr *)&client_addr, &client_addr_len);

        if (strcmp(pat.data, "##") == 0)
        {
            break;
        }
        if (bytes_received > 0 && receive[pat.seqno] == -1)
        {
            receive[pat.seqno] = 1;
            pack[pat.seqno].seqno = pat.seqno;
            strcpy(pack[pat.seqno].data, pat.data);
            pack[pat.seqno].ctime = 0;
            printf("Received data from data chunk: %s\n", pack[pat.seqno].seqno);
        }
        if (i % 3 == 0)
        {
            // printf("%d", pat.seqno);
            usleep(100000);
        }
        char str[1024];
        sprintf(str, "%d", pat.seqno);
        struct packet paj;
        paj.ctime = 0;
        paj.seqno = pat.seqno;
        ssize_t bytes_sent = sendto(server_socket, &paj, sizeof(paj), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
        if(bytes_sent > 0)
        {
            printf("sent acknowledgement for data chunk %d\n", paj.seqno);
        }
        i++;
    }
    memset(hoo, 0, sizeof(hoo));
    for (int i = 0; i < y; i++)
    {
        strcat(hoo, pack[i].data);
    }
    printf("TEXT: %s", hoo);
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
    // printf("%d", nchunks);
    char arr[1024];
    sprintf(arr, "%d", nchunks);
    ssize_t bytes_sent = sendto(server_socket, arr, sizeof(arr), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
    struct timeval curr_time;
    i = 0;
    char ok[1024];
    struct packet packt[1024];
    int count = 0;
    int unack[nchunks];
    memset(unack, -1, sizeof(unack));
    int no = 0;
    while ((no != nchunks) || count == 0)
    {
        struct packet paj;
        if (no < nchunks)
        {
            bzero(ok, sizeof(ok));
            strncpy(ok, message + (no * 10), 10);
            ok[strlen(ok)] = '\0';
            strcpy(packt[no].data, ok);
            packt[no].seqno = no;
            bytes_sent = sendto(server_socket, &packt[no], sizeof(packt[no]), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
            printf("Sent data packet %d\n",packt[no].seqno);
            gettimeofday(&curr_time, NULL);
            packt[no].ctime = curr_time.tv_usec;
            time_t he = curr_time.tv_sec;
            bzero(&paj, sizeof(paj));
            bytes_received = recvfrom(server_socket, &paj, sizeof(paj), O_NONBLOCK, (struct sockaddr *)&client_addr, &client_addr_len);
            gettimeofday(&curr_time, NULL);
            int d = paj.seqno;

            if(bytes_received > 0 && unack[d] != 0)
            {
                // printf("curr_time %ldcurr_ti :%ld\n curr: %ld\n entry: %ld\n",he,curr_time.tv_sec,curr_time.tv_usec,packt[d].ctime);
                // printf("TIME: %ld\n",(curr_time.tv_usec - packt[d].ctime));
            }
            if (bytes_received > 0 && unack[d] != 0 && (curr_time.tv_usec - packt[d].ctime) > 100000)
            {
                // printf("time :%ld\n", (curr_time.tv_usec - packt[d].ctime));
                count++;
                unack[d] = 1;
                for (int j = 0; j < nchunks; j++)
                {
                    if (unack[j] == 1)
                    {
                        printf("Retransmittinng data chunk %d\n", j);
                        ssize_t bytes_sent = sendto(server_socket, &packt[j], sizeof(packt[j]), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
                        printf("Sent data packet %d\n",packt[j].seqno);
                        gettimeofday(&curr_time, NULL);
                        pack[j].ctime = curr_time.tv_usec;
                        bzero(&paj, sizeof(struct packet));

                        ssize_t bytes_received = recvfrom(server_socket, &paj, sizeof(paj), O_NONBLOCK, (struct sockaddr *)&client_addr, &client_addr_len);
                        d = paj.seqno;
                        gettimeofday(&curr_time, NULL);
                        if (bytes_received > 0 && unack[d] != 0 && (curr_time.tv_usec - packt[d].ctime) <= 100000)
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
                no++;
                unack[d] = 0;
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
                        ssize_t bytes_sent = sendto(server_socket, &packt[j], sizeof(packt[j]), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
                        printf("Sent data packet %d\n",packt[j].seqno);
                        gettimeofday(&curr_time, NULL);
                        packt[j].ctime = curr_time.tv_usec;
                        bzero(&paj, sizeof(struct packet));

                        ssize_t bytes_received = recvfrom(server_socket, &paj, sizeof(paj), O_NONBLOCK, (struct sockaddr *)&client_addr, &client_addr_len);
                        int d = paj.seqno;
                        gettimeofday(&curr_time, NULL);
                        if (bytes_received > 0 && unack[d] != 0 && (curr_time.tv_usec - packt[d].ctime) <= 100000)
                        {
                            no++;
                            printf("Received acknowledgement for chunk %d\n", d);
                            count--;
                            unack[d] = 0;
                        }
                        else
                        {
                            unack[d] = 1;
                        }
                    }
                }
            }
        }

        i++;
    }
    struct packet patr;
    patr.ctime = 0;
    strcpy(patr.data, "##");
    patr.seqno = -1;
    bytes_sent = sendto(server_socket, &patr, sizeof(patr), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));

    close(server_socket);

    return 0;
}
