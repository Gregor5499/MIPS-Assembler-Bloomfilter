# MIPS Bloom Filter
 
A Bloom filter membership test implemented in MIPS assembly. This was written as coursework at TU Berlin, covering the fundamentals of processor architecture and low-level programming.
 
A Bloom filter is a space-efficient, probabilistic data structure used to test whether an element belongs to a set. Instead of storing the elements themselves, it runs each element through several hash functions and sets the corresponding bits in a fixed-size bit array. To check membership later, the same hash functions are applied to the query element: if *any* of the corresponding bits is unset, the element is **definitely not** in the set; if *all* of them are set, the element is **possibly** in the set (false positives can occur, but false negatives cannot).
 
## How This Implementation Works
 
The `hash(text, len, seed)` function is a custom hash function. Starting from `seed`, it runs 3 rounds over the string, on each character multiplying the running value by 31, adding the character's byte value, and rotating the result left by 15 bits (via a shift-left / shift-right / OR combination) to spread the bits further.
 
The `bloom_evaluate(text, bitmatrix, amt)` function first determines the string length by scanning for the terminating null byte. It then calls `hash` `amt` times with seeds `0` through `amt-1`, producing `amt` independent hash values, which simulates using several different hash functions. For each hash value, it computes `row = hash % 5` and `col = hash % 32` to address a single bit inside a 5×32-bit matrix (5 words = 160 bits total), builds a bitmask (`1 << col`), and ANDs it against the selected word. If a bit turns out to be `0`, the string is definitely not in the set and the function returns `0`; if all `amt` bits are set, the string is possibly in the set and it returns `1`.
 
Finally, `main` demonstrates the filter on the test string `"Apfel"` against a hard-coded bit matrix and prints the result.
 
Register save/restore around the `hash` call follows standard MIPS calling conventions (`$s` registers backed up on the stack, since the nested `hash` call would otherwise overwrite them).
 
## Running the Project
 
This program was written for and tested with **MARS** (MIPS Assembler and Runtime Simulator), a lightweight Java-based IDE that assembles MIPS code and executes it instruction by instruction while showing live register and memory contents, which makes it well suited for learning how a processor actually executes assembly.
 
1. Download the MARS `.jar` file from the official site: https://dpetersanderson.github.io/
2. Open `Bloom_filter.asm` in MARS
3. Assemble the file and run it
4. The console prints the input text and the return value of `bloom_evaluate` (`0` = definitely not in the set, `1` = possibly in the set)
## Context
 
This project was submitted as university coursework rather than built for real-world use. It's shared here to document hands-on experience writing and reasoning about MIPS assembly and low-level processor concepts.
