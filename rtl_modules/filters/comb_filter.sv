`timescale 1ns/1ps

`include "constants.svh"

/*  Comb filter

    Might be clocked with sample frequency?

    in -[add]-[delay(tau)]-+
        |                  +--out
        +--[mul(g)]--------+

    loop:
        out = delay.pop()
        delay.push(in + g * out)
*/
module comb_filter #(
    parameter WIDTH = 24,   // Integer width
    parameter MAXLEN = `MAX_FILTER_FIFO_LENGTH,
    parameter MID = 0       // Module ID for debug
) (
    input logic sample_clk,
    input logic signed [WIDTH+`FIXED_POINT-1:0] in,       // Data in
    input logic signed [WIDTH+`FIXED_POINT-1:0] tau, gain,// Tau and gain values

    output logic signed [WIDTH+`FIXED_POINT-1:0] out
);
    localparam WORD = WIDTH+`FIXED_POINT;
    logic signed [WORD-1:0] t = 0, g = 0;
    logic signed [WORD-1:0] out_node, out_reg = 0;
    logic signed [WORD-1:0] in_reg;
    logic signed [WORD*2-1:0] adder, mult;
    logic init = 0;

    initial begin
        $display("[comb_filter] tau = %d gain = %d in = %d", tau, gain, in);
    end


    fifo_delay_bram #(
        .WIDTH      (WORD),
        .MAXLEN     (MAXLEN)
    ) delay (
        .sample_clk (sample_clk),
        .enable     (1'b1),
        .len        (t),
        .in         (adder),
        .out        (out_node)
    );

    assign out = out_reg;

    always_ff @( posedge sample_clk ) begin
        t <= tau;
        g <= gain;

        if (init) begin
            mult <= g * out_node;
            in_reg <= in;
            /* Divide by 2 to avoid clipping if both in and out_node are close to max amplitude */
            adder <= (in_reg + (mult >>> `FIXED_POINT));
            out_reg <= out_node;
        end
        else begin
            init <= init + 1;
            adder <= 0;
            mult <= 0;
            in_reg <= 0;
            out_reg <= 0;
        end
    end

    always_ff @(posedge sample_clk)
        assert(!$isunknown(in)) else $error("[comb_filter] Input value was unknown");

endmodule