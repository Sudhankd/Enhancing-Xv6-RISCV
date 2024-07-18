SPECIFICATION-4

Differences between TCP  and UDP code implemented:
Data sequencing:
There is no big difference between in data sequencing , TCP also handles this by sequence number field in the data packets that are being sent.
Data retransmission:
If a TCP packet is not acknowledged by the receiver within a reasonable time (determined by various factors, including round-trip time estimation and congestion control algorithms), TCP will automatically retransmit the unacknowledged packet. This ensures reliability and data integrity without the need for manual retransmissions.

FLOW CONTROL IMPLEMENTATION:
Here are the steps to add a simple flow control mechanism to the code:
    1. Define a Receiver Window Size: Decide on a maximum number of packets the receiver can accept at a given time. This represents the receiver's buffer capacity.
    2. Maintain a Sender Window: Create a sender window that keeps track of unacknowledged packets and their status. The sender window should be a queue or array that holds packets waiting for acknowledgment.
    3. Sender Congestion Control (Optional): You can implement a basic form of congestion control to avoid overloading the network or the receiver. One simple approach is to limit the sender's window size based on network conditions or available receiver buffer space.
    4. Receiver Acknowledgments: Modify the receiver to send acknowledgments for received packets. The acknowledgment should include information about the highest sequence number received and the current receiver window size.
    5. Sender Monitoring: The sender should continuously monitor acknowledgments from the receiver and adjust its sending rate accordingly. If the receiver's window size is small, the sender should reduce the rate of sending new packets. Conversely, if the window size is large, the sender can increase its sending rate.
    6. Packet Buffering: Both the sender and receiver should maintain packet buffers to store and manage out-of-order packets. The sender's buffer should hold packets waiting for acknowledgment, and the receiver's buffer should store received packets in the correct order.
    7. Timeouts and Retransmissions: Implement a timeout mechanism on the sender side. If a packet is not acknowledged within a reasonable time, it should be retransmitted. Use an exponential backoff or similar strategy to handle retransmissions.
    8. Packet Duplication Handling: Add logic to the receiver to handle potential packet duplication or out-of-order delivery due to network issues.
Implementation:
    • Maintain a receiver window size variable on the receiver side.
    • Implement sender and receiver buffers to store packets.
    • Sender: Send packets within the receiver's window size.
    • Receiver: Send acknowledgments with the highest received sequence number and the current window size.
    • Sender: Monitor acknowledgments and adjust the sender window size based on received acknowledgments and congestion control rules.
    • Sender: Implement timeouts and retransmissions for unacknowledged packets.

Basic code:
      {
int congestion_threshold = 10; // Adjust as needed

// Monitor receiver buffer space
int available_buffer_space = ... // Get the available receiver buffer space

// Limit sender's window size based on congestion control
if (available_buffer_space < congestion_threshold)
{
// Reduce sender's window size
sender_window_size = available_buffer_space;
}
else
{
// Increase sender's window size (congestion avoidance)
sender_window_size += 1; // Or use another algorithm
}

// Sender window management (send packets within the current window)
for (int i = 0; i < sender_window_size; i++)
{
if (packets[i] is not acknowledged)
{
// Send the packet
}
}
}
      
