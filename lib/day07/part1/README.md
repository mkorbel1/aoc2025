# Day 7, Part 1

<https://adventofcode.com/2025/day/7>

Let's take the inputs as a vector that's the width of the input diagram, where 0 is empty space (`.`) and 1 is a splitter (`^`). Each row gets fed in each cycle, and we update an internal state of where the current beam is located. We can increment a counter with the count hit that row.