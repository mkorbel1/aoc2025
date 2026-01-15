# Day 2, Part 1

First, algorithmically, we most likely cannot just loop through every entry between the start and end of the range (naive solution) because it would take too long.  Even if it doesnt for the input given, that's a boring solution.  Instead, since we only need to see if the first half equals the second half of each number, we just need to check if a duplicate of the first half in the second half is valid in the range.

Thus, we can make a counter that starts at the first half of the digits and increment it until it is greater than or equal to the end of the range first half of the digits, then check if that first half duplicated into the second half exists in that range.

Since this is all in decimal, we need a representation of the numbers in hardware that can comprehend decimal.  We can use [Binary-coded Decimal](https://en.wikipedia.org/wiki/Binary-coded_decimal) for this.

