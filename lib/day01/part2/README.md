# Day 1, Part 2

<https://adventofcode.com/2025/day/1>

Now we have to count every time we roll past zero.  Fortunately, there's an underflow and overflow indication from the counters we can leverage for that.

By inspection, the largest input seems to never be more than 1000, so instead of paying for divider or modulo hardware, let's just iteratively reduce by 100 until the amount is less than 100.  This means that every request is going to be multi-cycle, so let's use a Ready/Valid handshake to backpressure while the machine is busy.  This will take more cycles, but suppose we're optimizing for less hardware or more relaxed timing or something.

We can use the `FiniteStateMachine` abstraction to make a simple state machine that controls and keeps track of what we are counting.  We can use the `ReadyValidTransmitterAgent` to help us construct a testbench that handles sequencing and backpressure gracefully.