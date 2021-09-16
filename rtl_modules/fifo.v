`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NTNU TDT4295 Computer Project FALL21
// Engineer:
// 
// Create Date: 09/09/2021 01:37:17 PM
// Design Name: 
// Module Name: audio_fifo
// Project Name: Audio Project - Synth
// Target Devices: 
// Tool Versions: 
// Description: FIFO module created for use in Comb filter
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fifo #(
    parameter WIDTH = 12, 
    parameter LEN = 2048
)(
    input clk,
    input resetn,
    input enable,
    input [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);

    integer i;
    reg [WIDTH-1:0] queue[0:LEN-1];
    assign out = queue[LEN-1];

    always @ (posedge(clk)) begin
        if (enable) begin
            queue[0] <= in;
            for (i = 1; i < LEN; i = i + 1) begin
                queue[i] <= queue[i-1];
            end
        end
        else
            for (i = 0; i < LEN; i = i + 1) begin
                queue[i] <= queue[i];
            end
`ifdef SIM
        for (i = 0; i < LEN; i = i + 1)
            $display("%d: %d", i, queue[i][WIDTH-1:0]);
`endif
    end
endmodule
