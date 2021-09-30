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
// Description: FIFO buffer module created for use in Comb filter. A value inserted
// will be assigned to out after LEN clock cycles of enable signal high.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fifo_delay #(
    parameter WIDTH = 12, 
    parameter LEN = 2048
)(
    input clk,
    input rstn,
    input enable,
    input [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);

    logic [WIDTH-1:0] queue[0:LEN-1];

    assign out = queue[LEN-1];

    always_ff @ (posedge clk) begin
        if (!rstn) queue <= '{default:0};
        if (enable) begin
            queue[0] <= in;
            for (int i = 1; i < LEN; i = i + 1) begin
                queue[i] <= queue[i-1];
            end
        end
        else begin
            for (int i = 0; i < LEN; i = i + 1) begin
                queue[i] <= queue[i];
            end
        end
`ifdef DEBUG
        for (int i = 0; i < LEN; i = i + 1) begin
            $display("[fifod] %d: %d", i, queue[i][WIDTH-1:0]);
        end
`endif
    end
endmodule
