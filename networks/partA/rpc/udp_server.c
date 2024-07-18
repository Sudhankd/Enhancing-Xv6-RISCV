#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
    int server_socket;
    struct sockaddr_in server_addr, client_addr1, client_addr2;
    socklen_t client_addr1_len = sizeof(client_addr1);
    socklen_t client_addr2_len = sizeof(client_addr1);
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
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    // Bind the socket
    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Binding failed");
        close(server_socket);
        exit(1);
    }

    while (1)
    {
        char buffer1[1024];
        // Receive data from client
        ssize_t bytes_received = recvfrom(server_socket, buffer1, sizeof(buffer1), 0, (struct sockaddr *)&client_addr1, &client_addr1_len);
        if (bytes_received == -1)
        {
            perror("Receiving data failed");
            // close(server_socket);
            break;
        }
        buffer1[bytes_received] = '\0';
        // Process received data
        // printf("Received data from client: %s\n", buffer);

        char buffer2[1024];
        // Receive data from client
        bytes_received = recvfrom(server_socket, buffer2, sizeof(buffer2), 0, (struct sockaddr *)&client_addr2, &client_addr2_len);
        if (bytes_received == -1)
        {
            perror("Receiving data failed");
            // close(server_socket);
            break;
        }
        buffer2[bytes_received] = '\0';
        // Process received data
        // printf("Received data from client: %s\n", buffer);

        char judgement[1024];
        if (strcmp(buffer1, buffer2) == 0)
        {
            strcpy(judgement, "D");
            judgement[1] = '\0';
        }
        else if (strcmp(buffer1, "R") == 0)
        {
            // printf("1%s1", buffer1);
            // printf("2%s2", buffer2);
            if (strcmp(buffer2, "P") == 0)
            {
                strcpy(judgement, "B");
            }
            else
            {
                strcpy(judgement, "A");
            }
            judgement[1] = '\0';
        }
        else if (strcmp(buffer1, "S") == 0)
        {
            if (strcmp(buffer2, "R") == 0)
            {
                strcpy(judgement, "B");
            }
            else
            {
                strcpy(judgement, "A");
            }
            judgement[1] = '\0';
        }
        else if (strcmp(buffer1, "P") == 0)
        {
            if (strcmp(buffer2, "S") == 0)
            {
                strcpy(judgement, "B");
            }
            else
            {
                strcpy(judgement, "A");
            }
            judgement[1] = '\0';
        }

        ssize_t bytes_sent = sendto(server_socket, judgement, strlen(judgement), 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
        if (bytes_sent == -1)
        {
            perror("Sending data failed");
            // close(server_socket);
            break;
            // exit(1);
            // exit(1);
        }

        bytes_sent = sendto(server_socket, judgement, strlen(judgement), 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2));
        if (bytes_sent == -1)
        {
            perror("Sending data failed");
            // close(server_socket);
            break;
            // exit(1);
        }

        memset(buffer1, 0, sizeof(buffer1));
        bytes_received = recvfrom(server_socket, buffer1, sizeof(buffer1), 0, (struct sockaddr *)&client_addr1, &client_addr1_len);
        if (bytes_received == -1)
        {
            perror("Receiving data failed");
            // close(server_socket);
            exit(1);
        }
        buffer1[bytes_received] = '\0';

        memset(buffer2, 0, sizeof(buffer2));
        bytes_received = recvfrom(server_socket, buffer2, sizeof(buffer2), 0, (struct sockaddr *)&client_addr2, &client_addr2_len);
        if (bytes_received == -1)
        {
            perror("Receiving data failed");
            // close(server_socket);
            exit(1);
        }
        buffer2[bytes_received] = '\0';

        if (strcmp(buffer1, "Y") == 0 && strcmp(buffer2, "Y") == 0)
        {
            // printf("hi");
            bytes_sent = sendto(server_socket, buffer1, strlen(buffer1), 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
            if (bytes_sent == -1)
            {
                perror("Sending data failed");
                // close(server_socket);
                break;
                // exit(1);
                // exit(1);
            }
            bytes_sent = sendto(server_socket, buffer2, strlen(buffer2), 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2));
            if (bytes_sent == -1)
            {
                perror("Sending data failed");
                // close(server_socket);
                break;
                // exit(1);
                // exit(1);
            }

            // printf("r%s %sr", ready_message1, ready_message2);
            // printf("b%s %sb", buffer1, buffer2);
            // continue;
        }
        else
        {
            // printf("hello");
            memset(buffer1, 0, sizeof(buffer1));
            memset(buffer2, 0, sizeof(buffer2));
            strcpy(buffer1,"Q");
            strcpy(buffer2,"Q");
            bytes_sent = sendto(server_socket, buffer1, strlen(buffer1), 0, (struct sockaddr *)&client_addr1, sizeof(client_addr1));
            if (bytes_sent == -1)
            {
                perror("Sending data failed");
                // close(server_socket);
                break;
                // exit(1);
                // exit(1);
            }
            bytes_sent = sendto(server_socket, buffer2, strlen(buffer2), 0, (struct sockaddr *)&client_addr2, sizeof(client_addr2));
            if (bytes_sent == -1)
            {
                perror("Sending data failed");
                // close(server_socket);
                break;
                // exit(1);
                // exit(1);
            }
            // close(client_socket1);
            // close(client_socket2);
            break;
        }
        // close(client_socket1);
        // close(client_socket2);
    }
    // Close socket
    close(server_socket);

    return 0;
}
