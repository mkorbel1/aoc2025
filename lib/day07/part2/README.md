# Day 7, Part 2

<https://adventofcode.com/2025/day/7>

This time, instead of just keeping track of whether a laser was present or not at each stage, we also need to keep track of the current number of paths that could have been used to get to that laser point.

Each row (cycle), if there's a split and a generated laser, we add the number of paths from the prior stage for any splitter (there could be two) that could/would have generated that laser.

At the end, we need to add up all of the current numbers of paths, which is actually a decent amount of addition.  We can use a pipelined reduction tree of adders to give a result some cycles later, so just don't check the result until some cycles after we're done processing inputs.

This is kind of a lot of adders, and they could be decently wide, but it should scale ok for a bit and we can just reduce the clock speed a bit if needed.  The cycle time should only be constrained by approximately one of the big adders.