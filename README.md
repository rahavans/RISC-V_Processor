# RISC-V Processor

Hi! I'm designing a custom processor in preparation for my Computer Architecture class (ECE320), to understand the functionality of computer processors at a fundamental level. 

I will get into my decisions as for why I incorporated certain features to design a custom processor, rather than a traditional RISC-V Processor, but closely retained most key elements. 

ISA: I chose to use the RV32I ISA since it is is the more minimalistic base instruction set. Much of the extensions such as RV32M and RV32A would be more of an extension. To understand the fundamental workflow of a processor, I felt that RV32I's ISA would suffice. The link to the ISA is as follows: https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf

Pipeline Stages: I decided to make a 5-stage pipeline in order to increase overall throughput when executing a larger set of instructions from memory. The stages consisted of a fetch stage to load the instruction from memory to the instruction register, a decoding stage to determine how to handle the instruction, an execution stage to complete the computation, a memory access stage that dealt with data memory in the processor, and finally the write-back stage that completed the instruction.

Signed vs Unsigned: I chose to use signed arithmetic since RV32I contains some unsigned instructions, so to cover a wide range of data, I chose to output signed arithmetic, and typecast values to unsigned using $unsigned() to handle unsigned instructions.

Memory Address/File: For functionality purposes, I chose to use a memory file using the $readmemb() function, that contained 32 bit instructions as per RV32I instruction formats. Although this design would not be synthesizable, it would be useful to prove functionality through simulation, as in order for the design to be synthesizable, I would have to use some sort of external memory device and communication protocols. For my case, I opted for a memory file, purely to test functionality of my processor design.

Decoding Process: I decoded the instruction passed by retrieiving the opcode to divide the instruction into its specific type, and from there extracted the immediate values, and source registers to complete the operations. To store immediate values, I used temporary registers GPR5 and GPR6 to store immediate values as RV32I defines them as temporary registers. I then pipelined my decoded instruction till the write-back stage to determine the destination register. 