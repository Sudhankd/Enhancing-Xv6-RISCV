#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
    int client_socket;
    struct sockaddr_in server_addr;
    socklen_t server_addr_len = sizeof(server_addr);

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

    // Send data to server
    // const char* message = "Hello, UDP Server!";
    while (1)
    {
        char message[1024];
        scanf("%s", message);
        message[strlen(message)] = '\0';
        ssize_t bytes_sent = sendto(client_socket, message, strlen(message), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
        if (bytes_sent == -1)
        {
            perror("Sending data failed");
            close(client_socket);
            exit(1);
        }

        char buffer[1024];
        ssize_t bytes_received = recvfrom(client_socket, buffer, sizeof(buffer), 0, (struct sockaddr *)&server_addr, &server_addr_len);
        if (bytes_received == -1)
        {
            perror("Receiving data failed");
            close(client_socket);
            exit(1);
        }
        buffer[bytes_received] = '\0';
        if (strcmp(buffer, "D") == 0)
        {
            // printf("%s", buffer);
            printf("DRAW\n");
        }
        else if (strcmp(buffer, "A") == 0)
        {
            printf("YOU WIN!\n");
        }
        else
        {
            printf("YOU LOST\n");
        }
        char option[1024];
        scanf("%s", option);
        option[strlen(option)] = '\0';

        bytes_sent = sendto(client_socket, option, strlen(option), 0, (struct sockaddr *)&server_addr, sizeof(server_addr));
        if (bytes_sent == -1)
        {
            perror("Sending data failed");
            close(client_socket);
            exit(1);
        }

        memset(buffer,0,sizeof(buffer));
        bytes_received = recvfrom(client_socket, buffer, sizeof(buffer), 0, (struct sockaddr *)&server_addr, &server_addr_len);
        if (bytes_received == -1)
        {
            perror("Receiving data failed");
            close(client_socket);
            exit(1);
        }
        buffer[bytes_received] = '\0';

        if (strcmp(buffer, "Y") == 0)
        {
            continue;
            // send(client_socket, "Y", strlen("Y"), 0);
        }
        else
        {
            break;
        }

        // printf("Data received from udp server : %s",buffer);
        // Close socket
    }
    close(client_socket);
    return 0;
}
