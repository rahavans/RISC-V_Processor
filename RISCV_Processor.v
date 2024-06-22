`timescale 1ns / 1ps

`define opcode IR[6:0]
`define R_type 7'b0110011 
`define I_type 7'b0010011
`define S_type 7'b0100011
`define B_type 7'b1100011
`define U_type 7'b0110111
`define J_type 7'b1101111
`define load 7'b0000011

/*
R-type:  | funct7 | rs2 | rs1 | funct3 | rd | opcode |
I-type:  | imm[11:0] | rs1 | funct3 | rd | opcode |
S-type:  | imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode |
B-type:  | imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode |
U-type:  | imm[31:12] | rd | opcode |
J-type:  | imm[20|10:1|11|19:12] | rd | opcode |
*/

module RISCV_Processor(
    input clk,
    input rst,
    input [31:0] instruction,
    output reg [31:0] GPR [31:0]
);
reg [31:0] IR;
reg [31:0] GPR [31:0];


always@(*) begin
    case(`opcode)
    `R_type: begin
        if(IR[14:12] == 3'b000 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] + GPR[IR[24:20]]; // ADD
        end 
        else if (IR[14:12] == 3'b000 && IR[31:25] == 7'b0100000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] _ GPR[IR[24:20]]; // SUB
        end
        else if (IR[14:12] == 3'b100 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] ^ GPR[IR[24:20]]; // XOR
        end
        else if(IR[14:12] == 3'b110 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] | GPR[IR[24:20]]; // OR
        end
        else if(IR[14:12] == 3'b111 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] & GPR[IR[24:20]]; // AND
        end
        else if(IR[14:12] == 3'b001 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] << GPR[IR[24:20]]; // LEFT SHIFT
        end
        else if(IR[14:12] == 3'b101 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] >> GPR[IR[24:20]]; // RIGHT SHIFT
        end
        else if(IR[14:12] == 3'b101 && IR[31:25] == 7'b0100000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] >>> GPR[IR[24:20]]; // ARITHMETIC RIGHT SHIFT
        end
        else if(IR[14:12] == 3'b010 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = ($signed(GPR[IR[19:15]]) < $signed(GPR[IR[24:20]])) ? 1'b1 : 1'b0; // SET LESS THAN
        end 
        else if (IR[14:12] == 3'b011 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = (GPR[IR[19:15]] < GPR[IR[24:20]]) ? 1'b1 : 1'b0; // SET LESS THAN UNSIGNED
        end
    end
    `I_type: begin
        GPR[5] = {{20{IR[31]}}, IR[31:20]}; // EXTRACT IMMEDIATE VALUE. SIGN EXTEND TO 32 BITS, AND STORE IN TEMP REGISTER

        if(IR[14:12] == 3'b000) begin
            GPR[IR[11:7]] = (GPR[IR[19:15]] + GPR[5]); // ADDI
        end
        else if(IR[14:12] == 3b'100) begin
            GPR[IR[11:7]] = (GPR[IR[19:15]] ^ GPR[5]); // XORI
        end
        else if(IR[14:12] == 3b'110) begin 
            GPR[IR[11:7]] = (GPR[IR[19:15]] | GPR[5]); // ORI
        end
        else if(IR[14:12] == 3b'111) begin 
            GPR[IR[11:7]] = GPR[IR[19:15]] & GPR[5]; // ANDI
        end
        else if(IR[14:12] == 3b'001 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] << IR[24:20]; // SLLI
        end
        else if(IR[14:12] == 3b'101 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] >> IR[24:20]; // SRLI
        end
        else if(IR[14:12] == 3b'101 && IR[31:25] == 7'b0100000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] >>> IR[24:20]; // SRAI
        end
        else if(IR[14:12] == 3b'010) begin
            GPR[IR[11:7]] = ($signed(GPR[IR[19:15]]) < $signed(IR[24:20])) ? 1'b1 : 1'b0; // SLTI
        end
        else if(IR[14:12] == 3b'011) begin
            GPR[IR[11:7]] = (GPR[IR[19:15]] < IR[24:20]) > 1'b1 : 1'b0; // SLTIU
        end
    end
    endcase
end

endmodule