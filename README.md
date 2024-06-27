# RISC-V Processor

Hi! I'm designing a custom processor in preparation for my Computer Architecture class (ECE320), to understand the functionality of computer processors at a fundamental level. 

I will get into my decisions as for why I incorporated certain features to design a custom processor, rather than a traditional RISC-V Processor, but closely retained most key elements. 

Insturction Set: I opted to use the RV32I Instruction Set because of its simplicity, and range of instructions since it covers the fundamental instructions offered in RISC-V. Given that this project aims to deepen my understanding of the inner workings of a processor, RV32I provides the correct balance of instructional value and accessibility. The Instruction Set can be found here: https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf

Pipeline Stages: I developed a 5-stage pipeline to fetch instructions, decode them and extract their values, execute arithmetic and logical operations in the ALU, access memory if required, and complete a final write-back stage of the computations from the ALU or memory to the general-purpose registers. This suggested higher overall throughput due to its pipelined nature, allowing for more instructions to be processed over time.

Signed vs Unsigned: I chose to use signed arithmetic for the most part since RV32I offered some unsigned operations, so the general arithemtic and logical operations should opt to use signed arithmetic instead. 

Memory Address/File: I chose to use the $readmemb() function to read a memory file and store it in program memory. Although $readmemb() is not synthesizable, it suffices to prove functionality of the processor. The memory file would consist of 32 instructions that are 32 bits long, and get stored into program memory upon execution. Data memory within the processor (RAM) is also initialized to a register array of 32 of size 32 bits. Both can get appropriately altered as per one's liking, as there are no restrictions on size of memory within the program itself, as long as the instruction length is still 32 bits. 

Decoding Process: As per RV32I guidelines, the approporiate source registers, immediate values, and destination register are extracted from the instruction and stored into registers, for usage in the pipeline to complete the instruciton. 

Hazard Handling: This was a major challenge I faced. The key instances where I had to handle data hazards was during branching using the program counter, and subsequent instruction usage in the pipeline. I chose to avoid subsequent usage in the pipeline during testing by sending NOPs in my test cases as a temporary solution, however, during branching, I set a flag that generates NOP instructions while a branch instruction is being completed, to avoid the program counter from being altered. This way, the correct instruction is fetched next. This method of stalling does compromise throughput, however, at this point, I would suggest that hazard handling for subsequent instruction usage and possible data forwarding would be a next step improvement for this project. As for subsequent instructions, using this same flagging technique is possible, however, that would definitely be a challenge I will tackle in a newer iteration of this project. 

Compiling: I used the Icarus Verilog HDL compiler with SystemVerilog 2012 standards to support the general purpose register set initialization. Ths shell command is as follows:

iverilog -g 2012 tb_processor.v RISCV_Processor.v

Then, the testbench's output can be seen simply by running ./a.out in the command shell

Next Steps: Developing testbenches and testing!
