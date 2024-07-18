#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

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

    // Receive data from client
    ssize_t bytes_received = recvfrom(server_socket, buffer, sizeof(buffer), 0, (struct sockaddr *)&client_addr, &client_addr_len);
    if (bytes_received == -1)
    {
        perror("Receiving data failed");
        close(server_socket);
        exit(1);
    }
    buffer[bytes_received] = '\0';
    // Process received data
    printf("Received data from client: %s\n", buffer);
    const char *message = "Hello, i'm the mighty UDP Server!";
    ssize_t bytes_sent = sendto(server_socket, message, strlen(message), 0, (struct sockaddr *)&client_addr, sizeof(client_addr));
    if (bytes_sent == -1)
    {
        perror("Sending data failed");
        close(server_socket);
        exit(1);
    }

    // Close socket
    close(server_socket);

    return 0;
}
