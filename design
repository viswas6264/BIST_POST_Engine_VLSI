`timescale 1ns/1ps

// 4-bit full adder
module full_adder(
    input a, b, cin,
    output sum, cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (b & cin) | (cin & a);
endmodule

module adder(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire c1, c2, c3;
    full_adder fa0 (a[0], b[0], cin, sum[0], c1);
    full_adder fa1 (a[1], b[1], c1,  sum[1], c2);
    full_adder fa2 (a[2], b[2], c2,  sum[2], c3);
    full_adder fa3 (a[3], b[3], c3,  sum[3], cout);
endmodule

// LFSR Pattern generator
module lfsr (
    input clk,
    input reset,
    output [3:0] rand_num
);
    reg [3:0] state = 4'b0001;   // Seed 1 (non-zero)
    always @(posedge clk or posedge reset) begin
        if (reset)
            state <= 4'b0001;
        else begin
            state <= {state[2:0], state[0] ^ state[3]};   // Polynomial X^4 + X^3 + 1
        end
    end
    assign rand_num = state;
endmodule

// Analyzing the signal (Updated to 5-bit response to include cout)
module signature_analyzer (
    input clk,
    input reset,
    input [4:0] response,
    output [7:0] syndrome
);
    reg [7:0] sig_reg;
    always @(posedge clk or posedge reset) begin
        if (reset)
            sig_reg <= 8'h00;
        else
            sig_reg <= {sig_reg[6:0], ^(sig_reg[7:3] ^ response)};
    end
    assign syndrome = sig_reg;
endmodule
