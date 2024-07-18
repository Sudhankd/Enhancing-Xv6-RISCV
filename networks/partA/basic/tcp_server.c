#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
    int server_socket, client_socket;
    struct sockaddr_in server_addr, client_addr;
    socklen_t client_addr_len = sizeof(client_addr);
    char buffer[1024];

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
    server_addr.sin_port = htons(8080);
    server_addr.sin_addr.s_addr = INADDR_ANY;

    // Bind the socket
    if (bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Binding failed");
        close(server_socket);
        exit(1);
    }

    // Listen for incoming connections
    if (listen(server_socket, 5) == -1)
    {
        perror("Listening failed");
        close(server_socket);
        exit(1);
    }

    // Accept a client connection
    client_socket = accept(server_socket, (struct sockaddr *)&client_addr, &client_addr_len);
    if (client_socket == -1)
    {
        perror("Accepting client connection failed");
        close(server_socket);
        exit(1);
    }

    // while (1) {
    // Receive data from client
    ssize_t bytes_received = recv(client_socket, buffer, sizeof(buffer), 0);
    if (bytes_received == -1)
    {
        perror("Receiving data failed");
        close(client_socket);
        close(server_socket);
        exit(1);
    }
    buffer[bytes_received] = '\0';
    // Process received data
    printf("Received data from client: %s\n", buffer);

    // Send response to the client
    const char *response = "Hello from server!";
    ssize_t bytes_sent = send(client_socket, response, strlen(response), 0);
    if (bytes_sent == -1)
    {
        perror("Sending data failed");
        close(client_socket);
        close(server_socket);
        exit(1);
    }
    // }

    // Close sockets (not reached in this example)
    close(client_socket);
    close(server_socket);

    return 0;
}
