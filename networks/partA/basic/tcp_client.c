#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

int main()
{
    int client_socket;
    struct sockaddr_in server_addr;
    char buffer[1024];

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
    server_addr.sin_port = htons(8080);
    server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");

    // Connect to the server
    if (connect(client_socket, (struct sockaddr *)&server_addr, sizeof(server_addr)) == -1)
    {
        perror("Connection failed");
        close(client_socket);
        exit(1);
    }

    // while (1) {
    // Send data to server
    char message[1024];
    printf("Enter a message to send to the server: ");
    scanf("%s", message);
    ssize_t bytes_sent = send(client_socket, message, strlen(message), 0);
    if (bytes_sent == -1)
    {
        perror("Sending data failed");
        close(client_socket);
        exit(1);
    }

    // Receive response from the server
    ssize_t bytes_received = recv(client_socket, buffer, sizeof(buffer), 0);
    if (bytes_received == -1)
    {
        perror("Receiving data failed");
        close(client_socket);
        exit(1);
    }
    buffer[bytes_received] = '\0';
    printf("Received data from server: %s\n", buffer);
    // }

    // Close socket (not reached in this example)
    close(client_socket);

    return 0;
}
