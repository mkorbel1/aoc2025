# Day 8, Part 1

<https://adventofcode.com/2025/day/8>

Multiplication and square root are expensive, so we want to try to minimize those if we can.  We can probably avoid the square root all together since for comparisons of distance it won't matter.

We probably don't want to brute-force this, since 1000 comparisons with 1000 other entries is going to take a million cycles at least, if each comparison only took one cycle.  Even if that were ok in hardware, I don't want to wait for a simulation that long.

We can make the search for nearby groups easier by pre-grouping them spatially.  We can experiment with different partitioning (a configurable parameter).  We can approximate a sphere by:
- Take a cube
- If nothing is in the cube, expand the cube size in all directions by 1 partition
- If there is something in the cube, check that cube plus one up/down, left/right, forward/backward (since we're approximating), then check all of those one-by-one to find the closest one.

We then need a look-up to see if that entry has already been categorized into a circuit.
- If not, we just add it to the circuit (and increment the count for that circuit)
- If so, we need to scan the whole look-up to merge the circuits (and sum the counts of the circuits into the new one)

At the end, we scan through the circuit counts to find the 3 biggest ones.