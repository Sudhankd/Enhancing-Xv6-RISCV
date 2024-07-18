SPECIFICATION-3

FCFS:
The array PROC contains all the processes.

The code snippet represents a First-Come, First-Served (FCFS) scheduler in the xv6 operating system. It operates in an infinite loop and continually selects the next runnable process based on the process's creation time. The scheduler enables interrupts at the start, allowing the system to respond to external events. It iterates through all processes, identifying the one with the earliest creation time that is in the "RUNNABLE" state. After selection, it acquires the process's lock, marks it as "RUNNING," and performs a context switch to execute the chosen process. Once the process either finishes or blocks, the scheduler releases the lock and repeats the process selection loop. This ensures that processes are scheduled and executed in the order they arrived, adhering to the FCFS scheduling policy.
Changes made to xv6 to implement FCFS:
Included above snippet in scheduler function of kernel/proc.c.
Disabled the yield() function in kernel/trap.c using the SCHEDULER macro for FCFS policy(SCHEDULER_FCFS).
Modified Makefile.

MLFQ:
For MLFQ, i first iterated through the PROC array and checked if wait_time of a process exceeds the aging time, then the que_no is decreased(moved to next higher priority queue) and updated its entry_time to current ticks(This is equivalent to inserting at last).After this i iterated the PROC array again to find the runnable process to be scheduled to find the process in the highest priority queue(least que_no) and found the process with the min entry_time.entry_time is used to schedule processes within a queue it is initialised to ticks in the allocproc and also the initailly all the processes are initialised to que_no 0, and we run the process in the highest priority queue(min que_no) and with least entry_time in that queue. Before running it on the cpu we first update the entry time to ticks so that it is max compared to all other processes so it is inserted at athe end of the queue or every time when we get a timer interrupt we check for the timeslice of that process in that queue if it is greater than timeslice of the queue then its que_no is increased and in this case the timeslice is used to place the process at the end of the new queue. We also update the wait_time to ticks after it the process stops its execution to ticks. So always ticks – wait_time of a process gives the WAIT TIME of the process in that queue.
Modified files in xv6 for implementing MLFQ:
scheduler and allocproc functions in kernel/trap.c
usertrap function in kernel/proc.c.
MAKEFILE

For MLFQ
avg_time = 11
wtime = 145

For FCFS
avg_time = 10
wtime = 131

For RR
avg_time  = 10
wtime = 137


