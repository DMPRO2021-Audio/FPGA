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
    parameter MAXLEN = 2048
)(
    input clk,
    input sample_clk, // Rate at which data is propagated through queue
    input rstn,
    input enable, write,
    input [31:0] len,
    input [WIDTH-1:0] in,
    output [WIDTH-1:0] out
);

    logic [WIDTH-1:0] queue[0:MAXLEN-1] = '{default:0};

    assign out = queue[len-1];

    always_ff @ (posedge sample_clk) begin
        if (!rstn) queue <= '{default:0};
        if (enable) begin
            queue[0] <= in;
            for (int i = 1; i < MAXLEN; i = i + 1) begin
                queue[i] <= queue[i-1];
            end
        end
        else begin
            for (int i = 0; i < MAXLEN; i = i + 1) begin
                queue[i] <= queue[i];
            end
        end
`ifdef DEBUG
        $display("[fifovd] len = %d", len);
        for (int i = 0; i < len; i = i + 1) begin
            $display("[fifovd] %d: %d", i, queue[i][WIDTH-1:0]);
        end
`endif
    end
endmodule
