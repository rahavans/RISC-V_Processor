`timescale 1ns / 1ps

`define opcode IR_decode[6:0]
`define opcode_pl IR_decode_pipelined[6:0]
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
reg [31:0] IR_fetch;
reg [31:0] IR_decode;
reg [31:0] IR_decode_pipelined; // pipelined to execute
reg [31:0] IR_decode_pipelined_1; // pipelined to memory access
reg [31:0] IR_decode_pipelined_2; // pipelined to writeback
reg [31:0] execute;
reg [32:0] execute_w_overflow;
reg [31:0] mem_acess;
reg [31:0] write_back;

reg zero_flag;
reg negative_flag;
reg carry_flag;
reg overflow_flag;

genvar i;
generate
    for(i = 0; i < 32; i = i + 1) begin
        always @(posedge clk) begin
            if(rst) begin
                GPR[i] <= {32{1'b0}};
            end
        end
    end
endgenerate

always@(posedge clk) begin
    if(rst) begin
        IR_fetch <= {32{1'b0}};
        IR_decode <= {32{1'b0}};
        IR_decode_pipelined <= {32{1'b0}};
        execute <= {32{1'b0}};
        execute_w_overflow <= {33{1'b0}};
        mem_access <= {32{1'b0}};
        write_back <= {32{1'b0}};
        zero_flag <= 1'b0;
        negative_flag <= 1'b0;
        carry_flag <= 1'b0;
        overflow_flag <= 1'b0;
    end else begin
        IR_fetch <= instruction;
        IR_decode <= IR_fetch;
        GPR[5] <= {{20{IR_fetch[31]}}, IR_fetch[31:20]}; // EXTRACT IMMEDIATE VALUE. SIGN EXTEND TO 32 BITS, AND STORE IN TEMP REGISTER
    case(`opcode)
    IR_decode_pipelined <= IR_decode;
    `R_type: begin
        if(IR_decode[14:12] == 3'b000 && IR_decode[31:25] == 7'b0000000) begin
            execute_w_overflow <= GPR[IR_decode[19:15]] + GPR[IR_decode[24:20]]; // ADD
            execute <= ((GPR[IR_decode[19:15]] + GPR[IR_decode[24:20]]))[31:0];
            zero_flag <= ((GPR[IR_decode[19:15]] + GPR[IR_decode[24:20]]) == 0);
            carry_flag <= (GPR[IR_decode[19:15]] + GPR[IR_decode[24:20]])[32];
            negative_flag <= (GPR[IR_decode[19:15]] + GPR[IR_decode[24:20]])[31];
            overflow_flag <= ((GPR[IR_decode[19:15]][31] == GPR[IR_decode[24:20]][31]) && (execute[31] != GPR[IR_decode[19:15]][31]));
        end 
        else if (IR_decode[14:12] == 3'b000 && IR_decode[31:25] == 7'b0100000) begin
            execute_w_overflow <= GPR[IR_decode[19:15]] - GPR[IR_decode[24:20]]; // ADD
            execute <= (GPR[IR_decode[19:15]] - GPR[IR_decode[24:20]])[31:0];
            zero_flag <= ((GPR[IR_decode[19:15]] - GPR[IR_decode[24:20]]) == 0);
            carry_flag <= ((GPR[IR_decode[19:15]] - GPR[IR_decode[24:20]]))[32];
            negative_flag <= (GPR[IR_decode[19:15]] - GPR[IR_decode[24:20]])[31];
            overflow_flag <= ((GPR[IR_decode[19:15]][31] == GPR[IR_decode[24:20]][31]) && (execute[31] != GPR[IR_decode[19:15]][31]));
        end
        else if (IR_decode[14:12] == 3'b100 && IR_decode[31:25] == 7'b0000000) begin
            execute <= GPR[IR_decode[19:15]] ^ GPR[IR_decode[24:20]]; // XOR
            zero_flag <= ((GPR[IR_decode[19:15]] ^ GPR[IR_decode[24:20]]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] ^ GPR[IR_decode[24:20]])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3'b110 && IR_decode[31:25] == 7'b0000000) begin
            execute <= GPR[IR_decode[19:15]] | GPR[IR_decode[24:20]]; // OR
            zero_flag <= ((GPR[IR_decode[19:15]] | GPR[IR_decode[24:20]]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] | GPR[IR_decode[24:20]])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3'b111 && IR_decode[31:25] == 7'b0000000) begin
            execute <= GPR[IR_decode[19:15]] & GPR[IR_decode[24:20]]; // AND
            zero_flag <= ((GPR[IR_decode[19:15]] & GPR[IR_decode[24:20]]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] & GPR[IR_decode[24:20]])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3'b001 && IR_decode[31:25] == 7'b0000000) begin
            execute <= GPR[IR_decode[19:15]] << GPR[IR_decode[24:20]]; // LEFT SHIFT
            zero_flag <= ((GPR[IR_decode[19:15]] << GPR[IR_decode[24:20]]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] << GPR[IR_decode[24:20]])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3'b101 && IR_decode[31:25] == 7'b0000000) begin
            execute <= GPR[IR_decode[19:15]] >> GPR[IR_decode[24:20]]; // RIGHT SHIFT
            zero_flag <= ((GPR[IR_decode[19:15]] >> GPR[IR_decode[24:20]]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] >> GPR[IR_decode[24:20]])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3'b101 && IR_decode[31:25] == 7'b0100000) begin
            execute <= GPR[IR_decode[19:15]] >>> GPR[IR_decode[24:20]]; // ARITHMETIC RIGHT SHIFT
            zero_flag <= ((GPR[IR_decode[19:15]] >>> GPR[IR_decode[24:20]]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] >>> GPR[IR_decode[24:20]])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3'b010 && IR_decode[31:25] == 7'b0000000) begin
            execute <= ($signed(GPR[IR_decode[19:15]]) < $signed(GPR[IR_decode[24:20]])) ? 1 : 0; // SET LESS THAN
            zero_flag <= 1'b0;
            negative_flag <= 1'b0;
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end 
        else if (IR_decode[14:12] == 3'b011 && IR_decode[31:25] == 7'b0000000) begin
            execute <= (GPR[IR_decode[19:15]] < GPR[IR_decode[24:20]]) ? 1 : 0; // SET LESS THAN UNSIGNED
            zero_flag <= 1'b0;
            negative_flag <= 1'b0;
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
    end
    `I_type: begin
        if(IR_decode[14:12] == 3'b000) begin
            execute_w_overflow <= GPR[IR_decode[19:15]] + GPR[5]; // ADDI
            execute <= ((GPR[IR_decode[19:15]] + GPR[5]))[31:0];
            zero_flag <= ((GPR[IR_decode[19:15]] + GPR[5]) == 0);
            carry_flag <= (GPR[IR_decode[19:15]] + GPR[5])[32];
            negative_flag <= (GPR[IR_decode[19:15]] + GPR[5])[31];
            overflow_flag <= ((GPR[IR_decode[19:15]][31] == GPR[5][31]) && (execute[31] != GPR[IR_decode[19:15]][31]));
        end
        else if(IR_decode[14:12] == 3b'100) begin
            execute <= (GPR[IR_decode[19:15]] ^ GPR[5]); // XORI
            zero_flag <= ((GPR[IR_decode[19:15]] ^ GPR[5]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] ^ GPR[5])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3b'110) begin 
            execute <= (GPR[IR_decode[19:15]] | GPR[5]); // ORI
            zero_flag <= ((GPR[IR_decode[19:15]] | GPR[5]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] | GPR[5])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3b'111) begin 
            execute <= GPR[IR_decode[19:15]] & GPR[5]; // ANDI
            zero_flag <= ((GPR[IR_decode[19:15]] & GPR[5]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] & GPR[5])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3b'001 && IR_decode[31:25] == 7'b0000000) begin
            execute <= GPR[IR_decode[19:15]] << IR_decode[24:20]; // SLLI
            zero_flag <= ((GPR[IR_decode[19:15]] << GPR[5]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] << GPR[5])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3b'101 && IR_decode[31:25] == 7'b0000000) begin
            execute <= GPR[IR_decode[19:15]] >> IR_decode[24:20]; // SRLI
            zero_flag <= ((GPR[IR_decode[19:15]] >> GPR[5]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] >> GPR[5])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3b'101 && IR_decode[31:25] == 7'b0100000) begin
            execute <= GPR[IR_decode[19:15]] >>> IR_decode[24:20]; // SRAI
            zero_flag <= ((GPR[IR_decode[19:15]] >>> GPR[5]) == 0);
            negative_flag <= (GPR[IR_decode[19:15]] >>> GPR[5])[31];
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3b'010) begin
            execute <= ($signed(GPR[IR_decode[19:15]]) < $signed(GPR[5])) ? 1 : 0; // SLTI
            zero_flag <= 1'b0;
            negative_flag <= 1'b0;
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
        else if(IR_decode[14:12] == 3b'011) begin
            execute <= (GPR[IR_decode[19:15]] < GPR[5]) ? 1 : 0; // SLTIU
            zero_flag <= 1'b0;
            negative_flag <= 1'b0;
            carry_flag <= 1'b0;
            overflow_flag <= 1'b0;
        end
    end
    endcase
    if
end
end

endmodule