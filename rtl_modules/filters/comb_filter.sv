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
    parameter MAXDELAY = 4096
) (
    input logic clk, sample_clk, rstn,
    input logic signed [WIDTH+`FIXED_POINT-1:0] in,       // Data in
    input logic signed [WIDTH+`FIXED_POINT-1:0] tau, gain,// Tau and gain values
    input logic signed write,               // Enable updating 

    output logic signed [WIDTH+`FIXED_POINT-1:0] out
);
    localparam WORD = WIDTH+`FIXED_POINT;
    logic signed [WORD-1:0] t, g;
    logic signed [WORD-1:0] out_node = 0;
    logic signed [WORD-1:0] adder, mult = 0;
    logic fifo_write; // Propagate write signal
    logic [$clog2(2):0] counter;

    assign t = tau;
    assign g = gain;

    fifo_delay_bram #(
        .WIDTH  (WORD  ),
        .MAXLEN (MAXDELAY)
    ) delay (
        .clk    (clk),
        .sample_clk    (sample_clk),
        .rstn   (rstn),
        .enable (1'b1),
        //.write  (fifo_write),
        .len    (t),
        .in     (adder),
        .out    (out_node)
    );

    assign out = out_node;
    assign adder = in + ((g * out_node) >>> `FIXED_POINT);

    // always_ff @(posedge clk) begin

    //     mult <= g * out_node;
    //     adder <= in + (mult >>> `FIXED_POINT);
    // end

    always_ff @(posedge sample_clk)
        assert(!$isunknown(in)) else $error("[comb_filter] Input value was unknown");

    //     $strobe("[comb_filter] in = %x mult = %x, adder = %x. tau = %d, gain = %x", in, mult, adder, t, g);

    /* Set configuration values */
    // always_ff @(posedge clk) begin
    //     /* Clocked by sample_clk (48kHz): tau = 1 -> 0.02083 ms delay
    //     For a delay of 30 ms, set tau = 1440.  */
    //     fifo_write <= write;
    //     if (write) begin
    //         t <= tau;   // TODO: Properly configure length from delay value
    //         g <= gain;
    //     end
    // end
endmodule