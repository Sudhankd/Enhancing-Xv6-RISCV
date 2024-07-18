#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
    int server_socket, client_socket1, client_socket2;
    struct sockaddr_in server_addr, client_addr1, client_addr2;
    socklen_t client_addr_len1 = sizeof(client_addr1);
    socklen_t client_addr_len2 = sizeof(client_addr2);

    // Create socket
    server_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (server_socket == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Initialize server address
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(5566);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    // Bind the socket
    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Binding failed");
        close(server_socket);
        exit(1);
    }

    // Listen for incoming connections
    if (listen(server_socket, 2) == -1)
    {
        perror("Listening failed");
        close(server_socket);
        exit(1);
    }

    client_socket1 = accept(server_socket, (struct sockaddr *)&client_addr1, &client_addr_len1);
    if (client_socket1 == -1)
    {
        perror("Accepting client connection failed");
        close(server_socket);
        exit(1);
    }

    client_socket2 = accept(server_socket, (struct sockaddr *)&client_addr2, &client_addr_len2);
    if (client_socket2 == -1)
    {
        perror("Accepting client connection failed");
        close(server_socket);
        exit(1);
    }

    // char ready_message1[1024];
    // char ready_message2[1024];
    while (1)
    {
        // Accept a client connection

        // recv(client_socket1, ready_message1, sizeof(ready_message1), 0);
        // recv(client_socket2, ready_message2, sizeof(ready_message2), 0);

        char buffer1[1024];
        char buffer2[1024];
        // Receive data from client
        ssize_t bytes_received1 = recv(client_socket1, buffer1, sizeof(buffer1), 0);
        if (bytes_received1 == -1)
        {
            perror("Receiving data failed");
            close(client_socket1);
            close(client_socket2);
            break;
            // exit(1);
        }
        buffer1[bytes_received1] = '\0';

        ssize_t bytes_received2 = recv(client_socket2, buffer2, sizeof(buffer2), 0);
        if (bytes_received2 == -1)
        {
            perror("Receiving data failed");
            close(client_socket2);
            close(client_socket1);
            break;
            // exit(1);
        }

        buffer2[bytes_received2] = '\0';
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

        ssize_t bytes_sent1 = send(client_socket1, judgement, strlen(judgement), 0);
        if (bytes_sent1 == -1)
        {
            perror("Sending data failed");
            close(client_socket1);
            close(client_socket2);
            break;
            // exit(1);
        }
        ssize_t bytes_sent2 = send(client_socket2, judgement, strlen(judgement), 0);
        if (bytes_sent2 == -1)
        {
            perror("Sending data failed");
            close(client_socket2);
            close(client_socket1);
            break;
            // exit(1);
        }

        memset(buffer1, 0, sizeof(buffer1));
        memset(buffer2, 0, sizeof(buffer2));

        bytes_received1 = recv(client_socket1, buffer1, sizeof(buffer1), 0);
        if (bytes_received1 == -1)
        {
            perror("Receiving data failed");
            close(client_socket1);
            close(client_socket2);
            break;
            // close(server_socket);
            // exit(1);
        }
        buffer1[bytes_received1] = '\0';
    
        // printf("1%s1",buffer1);

        // recv(client_socket1, ready_message1, sizeof(ready_message1), 0);
        // recv(client_socket2, ready_message2, sizeof(ready_message2), 0);

        bytes_received2 = recv(client_socket2, buffer2, sizeof(buffer2), 0);
        if (bytes_received2 == -1)
        {
            perror("Receiving data failed");
            close(client_socket1);
            close(client_socket2);
            // close(server_socket);
            break;
        }
        buffer2[bytes_received2] = '\0';
        // printf("2%s2",buffer2);

        if (strcmp(buffer1, "Y") == 0 && strcmp(buffer2, "Y") == 0)
        {
            // printf("hi");
            ssize_t bytes_sent1 = send(client_socket1, buffer1, strlen(buffer1), 0);
            if (bytes_sent2 == -1)
            {
                perror("Sending data failed");
                close(client_socket2);
                close(client_socket1);
                break;
                // exit(1);
            }
            ssize_t bytes_sent2 = send(client_socket2, buffer1, strlen(buffer1), 0);
            if (bytes_sent2 == -1)
            {
                perror("Sending data failed");
                close(client_socket1);
                close(client_socket2);
                break;
                // exit(1);
            }

            // printf("r%s %sr", ready_message1, ready_message2);
            // printf("b%s %sb", buffer1, buffer2);
            // continue;
        }
        else
        {
            // printf("hello");
            memset(buffer1,0,sizeof(buffer1));
            memset(buffer2,0,sizeof(buffer2));
            bytes_sent1 = send(client_socket1, "Q", strlen("Q"), 0);
            if (bytes_sent1 == -1)
            {
                perror("Sending data failed");
                close(client_socket1);
                close(client_socket2);
                break;
                // exit(1);
            }
            bytes_sent2 = send(client_socket2, "Q", strlen("Q"), 0);
            if (bytes_sent2 == -1)
            {
                perror("Sending data failed");
                close(client_socket1);
                close(client_socket2);
                break;
                // exit(1);
            }
            close(client_socket1);
            close(client_socket2);
            break;
        }
        // close(client_socket1);
        // close(client_socket2);
    }

    // Close sockets (not reached in this example)

    // close(client_socket1);
    // close(client_socket2);
    close(server_socket);

    return 0;
}
