`timescale 1ns / 1ps

`define opcode IR[6:0]
`define R-type 7'b0110011 
`define I-type 7'b0010011
`define S-type 7'b0100011
`define B-type 7'b1100011
`define U-type 7'b0110111
`define J-type 7'b1101111
`define load 7'b0000011


module RISCV_Processor();
reg [31:0] IR;
reg [31:0] GPR [31:0];


always@(*) begin
    case(`opcode)
    R-type: begin
        if(IR[14:12] == 3'b000 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] + GPR[IR[24:20]]; // ADD
        end 
        else if (IR[14:12] == 3'b000 && IR[31:25] == 7'b0100000) begin
            GPR[IR[11:7]] = GPR[IR[19:15]] - GPR[IR[24:20]]; // SUB
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
            GPR[IR[11:7]] = (GPR[IR[19:15]] < GPR[IR[24:20]]) ? 1'b1:1'b0; // SET LESS THAN
        end 
        else if (IR[14:12] == 3'b011 && IR[31:25] == 7'b0000000) begin
            GPR[IR[11:7]] = (GPR[IR[19:15]] < GPR[IR[24:20]]) ? 1'b1:1'b0; // SET LESS THAN UNSIGNED
        end
    end
    endcase
end

endmodule