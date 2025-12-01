# Day 1, Part 1

<https://adventofcode.com/2025/day/1>

For this problem, we can just use a `Counter` component from ROHD-HCL with a maximum value and roll-over behavior, and stream the inputs in each cycle.  Then we just use a second `Counter` to count every time it equals zero!