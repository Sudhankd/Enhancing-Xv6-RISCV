#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
    int client_socket;
    struct sockaddr_in server_addr;

    // Create socket
    client_socket = socket(AF_INET, SOCK_STREAM, 0);
    if (client_socket == -1)
    {
        perror("Socket creation failed");
        exit(1);
    }

    // Initialize server address
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_port = htons(5566);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    // Connect to the server
    if (connect(client_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Connection failed");
        close(client_socket);
        exit(1);
    }
    char message[1024];
    char ready_message[1024];
    while (1)
    {
        // Send data to server
        printf("Enter a message to send to the server: ");
        scanf("%s", message);
        message[strlen(message)] = '\0';
        ssize_t bytes_sent = send(client_socket, message, strlen(message), 0);
        if (bytes_sent == -1)
        {
            perror("Sending data failed");
            close(client_socket);
            exit(1);
        }
        char buffer[1024];
        // send(client_socket, "READY", strlen("READY"), 0);

        // Receive response from the server
        // recv(client_socket, ready_message, sizeof(ready_message), 0);
        ssize_t bytes_received = recv(client_socket, buffer, sizeof(buffer), 0);
        if (bytes_received == -1)
        {
            perror("Receiving data failed");
            close(client_socket);
            exit(1);
        }
        buffer[bytes_received] = '\0';
        if (strcmp(buffer, "D") == 0)
        {
            printf("DRAW\n");
        }
        else if (strcmp(buffer, "A") == 0)
        {
            printf("YOU LOST!\n");
        }
        else
        {
            printf("YOU WIN\n");
        }
        char option[2];
        scanf("%s", option);
        option[strlen(option)] = '\0';
        ssize_t decision = send(client_socket, option, strlen(option), 0);
        if (decision == -1)
        {
            perror("Sending data failed");
            close(client_socket);
            exit(1);
        }
        memset(buffer, 0, sizeof(buffer));
        bytes_received = recv(client_socket, buffer, sizeof(buffer), 0);
        if (bytes_received == -1)
        {
            perror("Receiving data failed");
            close(client_socket);
            exit(1);
        }
        buffer[bytes_received] = '\0';
        // send(client_socket, "READY", strlen("READY"), 0);
        if (strcmp(buffer, "Y") == 0)
        {
            continue;
        }
        else
        {
            break;
        }
    }

    close(client_socket);

    return 0;
}
