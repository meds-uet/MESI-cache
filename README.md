# MESI-cache

## Overview

This project implements a **quad-core cache coherency system** using the **MESI (Modified, Exclusive, Shared, Invalid) protocol**. It ensures data consistency across multiple L1 caches while optimizing memory accesses. The system follows a **write-through policy** from L1 caches to the Cache Coherence Unit (CCU) and a **write-back policy** from L2 cache to main memory.

## Architecture

The system consists of the following components:

- **4 L1 Cache Controllers** – Each core has a private L1 cache that follows the MESI protocol.
- **FIFO** – Handles memory request buffering.
- **Arbiter** – Manages access to the shared communication bus.
- **Cache Coherence Unit (CCU)** – Ensures cache coherence using MESI.
- **L2 Cache Controller** – A shared L2 cache that stores data before accessing main memory.
- **Main Memory** – Stores data permanently, accessed via L2 cache.

### Block Diagram

[View Block Diagram](Block_Diagram)


## Cache Policies

- **Write-Through (L1 to CCU)** – Ensures that writes are immediately updated in the CCU.
- **Write-Back (L2 to Main Memory)** – Reduces memory traffic by writing only when a cache block is evicted.

## Testing and Verification

The design has been tested using:

1. **Vivado Simulation** – RTL-level verification for functional correctness.
2. **UVM (Universal Verification Methodology)** – Comprehensive testing using constrained-random verification and coverage analysis.

## Steps to Run the Project

1. Install **Vivado** for RTL simulation and synthesis.
2. Install **SystemVerilog UVM** for verification.
3. Load the source files into Vivado.
4. Run the Vivado simulation to verify functionality.
5. Use UVM-based testbenches for advanced verification.

## Contributors

- **Muhammad Zeeshan Malik** –  Design and Verification
- **Abeera Adnan** –  Design and Verification

##

