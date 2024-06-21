`timescale 1ns / 1ps

module Instruction_Decoder(
    input [31:0] instruction,
    output reg [6:0] opcode,
    output reg [4:0] rd,
    output reg [2:0] funct3,
    output reg [4:0] rs1,
    output reg [4:0] rs2,
    output reg [6:0] funct7,
    output reg [11:0] imm12,
    output reg [4:0] imm5,
    output reg [6:0] imm7,
    output reg [19:0] imm20
);
always @(*) begin
    opcode = instruction[6:0];
    rd = instruction[11:7];
    funct3 = instruction[14:12];
    rs1 = instruction[19:15];
    rs2 = instruction[24:20];
    funct7 = instruction[31:25];
    imm12 = instruction[31:20];
    imm5 = instruction[11:7];
    imm7 = instruction[31:25];
    imm20 = instruction[31:12];
end

/*
Instruction Types:
R-type:  | funct7 | rs2 | rs1 | funct3 | rd | opcode |
I-type:  | imm[11:0] | rs1 | funct3 | rd | opcode |
S-type:  | imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode |
B-type:  | imm[12|10:5] | rs2 | rs1 | funct3 | imm[4:1|11] | opcode |
U-type:  | imm[31:12] | rd | opcode |
J-type:  | imm[20|10:1|11|19:12] | rd | opcode |
*/
endmodule