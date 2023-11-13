Project Description:

This project aims to develop a comprehensive simulation tool for the Last Level Cache (LLC) in a multi-processor system. The LLC is an integral component that plays a crucial role in enhancing overall system performance by efficiently managing data access for up to four processors in a shared memory configuration.

Key Features:

Cache Configuration:

Total Capacity: 16MB
Line Size: 64 bytes
Associativity: 8-way set associative
Write Policies:

Write Allocate: The cache allocates space for a line on a write miss before updating it.
Write-Back: Subsequent writes to the same line are kept in the cache until the line is evicted.
Coherence Protocol:

MESI Protocol: Ensures cache coherence by tracking the state of each cache line (Modified, Exclusive, Shared, Invalid).
Replacement Policy:

Pseudo-LRU Scheme: Implements a pseudo-Least Recently Used algorithm for effective line replacement.
Inclusivity:

The cache maintains inclusivity with the next higher-level cache, ensuring consistency in data across the memory hierarchy.
Multi-Processor Support:

Designed to handle up to four processors in a shared memory configuration, providing a realistic simulation of cache interactions in a multi-processing environment.
