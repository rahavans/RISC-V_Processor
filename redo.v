`timescale 1ns / 1ps

`define opcode IR_fetch[6:0]
`define opcode_pl IR_decode[6:0]
`define R_type 7'b0110011 
`define I_type 7'b0010011
`define S_type 7'b0100011
`define B_type 7'b1100011
`define LUI 7'b0110111
`define AUIPC 7'b0010111
`define JAL 7'b1101111
`define JALR 7'b1101111
`define LOAD 7'b0000011

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
    output signed reg [31:0] GPR [31:0]
);
reg [31:0] IR_fetch;
reg [31:0] IR_decode;
reg [31:0] IR_decode_pipelined; // pipelined to execute
reg signed[31:0] execute;
reg signed[32:0] execute_w_overflow;
reg [31:0] write_back;

reg [31:0] program_mem [31:0];
reg [31:0] data_mem [31:0];

reg [31:0] rs1;
reg [31:0] rs2;
reg [31:0] imm;

reg zero_flag;
reg negative_flag;
reg carry_flag;
reg overflow_flag;
reg read_flag;

reg [2:0] count;
reg [31:0] PC;
genvar i;

generate
    for(i = 0; i < 32; i = i + 1) begin
        always @(posedge clk) begin
            if(rst) begin
                GPR[i] <= {32{1'b0}};
                program_mem[i] <= <= {32{1'b0}};
                data_mem[i] <= <= {32{1'b0}};
            end
        end
    end
endgenerate

always(@posedge clk) begin
    if(rst) begin
        read_flag <= 1'b0;
    end else begin
        if(read_flag == 1'b0) begin
        $readmemb("File path for a .mem file that contains 32 instructions", program_mem);
        // using $readmemb only for proof of functionality, in reality, would need to connect external controller for synthesis purposes
        end
        read_flag <= 1'b1;
    end
end

always@(posedge clk) begin
    if(rst) begin
        count <= {3{1'b0}};
        PC <= {32{1'b0}};
    end else begin
        if(read_flag == 1'b1) begin
        if(count < 3b'100) begin
            count <= count + 3b'001; // delay
        end else begin
            count <= 3b'000;
            PC <= PC + 4;
        end
    end
    end
end

always@(posedge clk) begin
    if(rst) begin
        IR_fetch <= {32{1'b0}};
    end else begin
        if(read_flag == 1'b1) begin
        IR_fetch <= program_mem[PC >> 2];
        end
    end
end

always@(posedge clk) begin
    if(rst) begin
        IR_decode <= {32{1'b0}};
        rs1 <= {32{1'b0}};
        rs2 <= {32{1'b0}};
        imm <= {32{1'b0}};
    end else begin
        if(read_flag == 1'b1) begin
        IR_decode <= IR_fetch;
    case(`opcode)
    `R_type: begin
        rs1 <= GPR[IR_fetch[19:15]];
        rs2 <= GPR[IR_fetch[24:20]];
        imm <= {32{1'b0}};
    end
    `I_type: begin
        rs1 <= GPR[IR_fetch[19:15]];
        rs2 <= {32{1'b0}};
        imm <= {{20{IR_fetch[31]}}, IR_fetch[31:20]}
    end
    `S_type: begin
        rs1 <= GPR[IR_fetch[19:15]];
        rs2 <= GPR[IR_fetch[24:20]];
        imm <= {20'b0, GPR[IR_fetch[31:25]], GPR[IR_fetch[11:7]]};
    end
    `B_type: begin
        rs1 <= GPR[IR_fetch[19:15]];
        rs2 <= GPR[IR_fetch[24:20]];
        imm <= {20'b0, GPR[IR_fetch[31:25]], GPR[IR_fetch[11:7]]};
    end
    `LUI: begin
        rs1 <= {32{1'b0}};
        rs2 <= {32{1'b0}};
        imm <= GPR[IR_fetch[31:12]];
    end
    `AUIPC: begin
        rs1 <= {32{1'b0}};
        rs2 <= {32{1'b0}};
        imm <= GPR[IR_fetch[31:12]];
    end
    `JAL: begin
        rs1 <= {32{1'b0}};
        rs2 <= {32{1'b0}};
        imm <= {11{IR_fetch[31]}, IR_fetch[31], IR_fetch[19:12], IR_fetch[20], IR_fetch[30:21], 1'b0};
    end
    `JALR: begin
        rs1 <= GPR[IR_fetch[19:15]];
        rs2 <= {32{1'b0}};
        imm <= {20{GPR[IR_fetch[31]]}, GPR[IR_fetch[31:20]]};
    end
    `LOAD: begin
        rs1 <= GPR[IR_fetch[19:15]];
        rs2 <= {32{1'b0}};
        imm <= {20{IR_fetch[31]}, IR_fetch[31:20]};
    end
    endcase
    end
    end
end

always@(posedge clk) begin
    if(rst) begin
        execute <= {32{1'b0}};
        execute_w_overflow <= {33{1'b0}};
        IR_decode_pl <= {32{1'b0}};
        zero_flag <= 1'b1;
        negative_flag <= 1'b0;
        carry_flag <= 1'b0;
        overflow_flag <= 1'b0;
    end else begin
        if(read_flag == 1'b1) begin
            IR_decode_pl <= IR_decode;
        case(`opcode_pl)
        `R_type: begin
            if(IR_decode[14:12] == 3'b000 && IR_decode[31:25] == 7'b0000000) begin
                execute_w_overflow <= rs1 + rs2; // ADD
                execute <= (rs1 + rs2)[31:0];
                zero_flag <= ((rs1 + rs2) == 0);
                carry_flag <= (rs1 + rs2)[33];
                negative_flag <= (rs1 + rs2)[32];
                overflow_flag <= ((rs1[31] == rs2[31]) && ((rs1 + rs2)[31] != rs1[31]));
            end
            else if(IR_decode[14:12] == 3'b000 && IR_decode[31:25] == 7'b0100000) begin
                execute_w_overflow <= rs1 - rs2; // SUB
                execute <= (rs1 - rs2)[31:0];
                zero_flag <= ((rs1 - rs2) == 0);
                carry_flag <= (rs1 - rs2)[33];
                negative_flag <= (rs1 - rs2)[32];
                overflow_flag <= ((rs1[31] == rs2[31]) && ((rs1 - rs2)[31] != rs1[31]));
            end
            else if(IR_decode[14:12] == 3'b100 && IR_decode[31:25] == 7'b0000000) begin
                execute <= rs1 ^ rs2; // XOR
                zero_flag <= ((rs1 ^ rs2) == 0);
                negative_flag <= (rs1 ^ rs2)[31];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3'b110 && IR_decode[31:25] == 7'b0000000) begin
                execute <= rs1 | rs2; // OR
                zero_flag <= ((rs1 | rs2) == 0);
                negative_flag <= (rs1 | rs2)[31];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3'b111 && IR_decode[31:25] == 7'b0000000) begin
                execute <= rs1 & rs2; // AND
                zero_flag <= ((rs1 & rs2) == 0);
                negative_flag <= (rs1 & rs2)[31];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3'b001 && IR_decode[31:25] == 7'b0000000) begin
                execute <= rs1 << rs2; // LEFT SHIFT
                zero_flag <= ((rs1 << rs2) == 0);
                negative_flag <= (rs1 << rs2)[31];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3'b101 && IR_decode[31:25] == 7'b0000000) begin
                execute <= rs1 >> rs2; // RIGHT SHIFT
                zero_flag <= ((rs1 >> rs2) == 0);
                negative_flag <= (rs1 >> rs2)[31];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3'b101 && IR_decode[31:25] == 7'b0100000) begin
                execute <= rs1 >>> rs2; // ARITHMETIC RIGHT SHIFT
                zero_flag <= ((rs1 >>> rs2) == 0);
                negative_flag <= (rs1 >>> rs2)[31];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3'b010 && IR_decode[31:25] == 7'b0000000) begin
                execute <= (rs1 < rs2) ? 1 : 0; // SLT
                zero_flag <= (rs1 > rs2) ? 1 : 0;
                negative_flag <= 1'b0;
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3'b011 && IR_decode[31:25] == 7'b0000000) begin
                execute <= ($unsigned(rs1) < $unsigned(rs2)) ? 1 : 0; // SLTU
                zero_flag <= ($unsigned(rs1) > $unsigned(rs2)) ? 1 : 0;
                negative_flag <= 1'b0;
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
        end
        `I_type: begin
            if(IR_decode[14:12] == 3'b000) begin
                execute_w_overflow <= rs1 + imm; // ADDI
                execute <= (rs1 + imm)[31:0];
                zero_flag <= ((rs1 + imm) == 0);
                carry_flag <= (rs1 + imm)[33];
                negative_flag <= (rs1 + imm)[32];
                overflow_flag <= ((rs1[31] == imm[31]) && ((rs1 + imm)[31] != rs1[31]));
            end
            else if(IR_decode[14:12] == 3b'100) begin
                execute <= rs1 ^ imm; // XORI
                zero_flag <= ((rs1 ^ imm) == 0);
                negative_flag <= (rs1 ^ imm)[32];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3b'110) begin
                execute <= rs1 | imm; // ORI
                zero_flag <= ((rs1 | imm) == 0);
                negative_flag <= (rs1 | imm)[32];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3b'111) begin
                execute <= rs1 & imm; // ANDI
                zero_flag <= ((rs1 & imm) == 0);
                negative_flag <= (rs1 & imm)[32];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3b'001 && IR_decode[31:25] == 7'b0000000) begin
                execute <= rs1 << imm; // SLLI
                zero_flag <= ((rs1 << imm) == 0);
                negative_flag <= (rs1 << imm)[32];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3b'101 && IR_decode[31:25] == 7'b0000000) begin
                execute <= rs1 >> imm; // SRLI
                zero_flag <= ((rs1 >> imm) == 0);
                negative_flag <= (rs1 >> imm)[32];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3b'101 && IR_decode[31:25] == 7'b0100000) begin
                execute <= rs1 >>> imm; // SRAI
                zero_flag <= ((rs1 >>> imm) == 0);
                negative_flag <= (rs1 >>> imm)[32];
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3b'010) begin
                execute <= (rs1 < imm) ? 1 : 0; // SLTI
                zero_flag <= (rs1 > imm) ? 1 : 0;
                negative_flag <= 1'b0;
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
            else if(IR_decode[14:12] == 3b'011) begin
                execute <= ($unsigned(rs1) < $unsigned(imm)) ? 1 : 0; // SLTU
                zero_flag <= ($unsigned(rs1) > $unsigned(imm)) ? 1 : 0;
                negative_flag <= 1'b0;
                carry_flag <= 1'b0;
                overflow_flag <= 1'b0;
            end
        end 
        endcase
        end
    end
end

always @(posedge clk) begin
    if(rst) begin
    end else begin
        
    end
end

endmodule

