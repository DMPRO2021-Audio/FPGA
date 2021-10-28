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
    logic signed [WORD-1:0] out_node;
    logic signed [WORD-1:0] adder;
    logic enable = 1;
    integer counter = 0;

    fifo_var_delay #(
        .WIDTH  (WORD  ),
        .MAXLEN (MAXDELAY)
    ) delay (
        .clk    (sample_clk),
        .rstn   (rstn    ),
        .enable (enable  ),
        .write  (write   ),
        .len    (t       ),
        .in     (adder   ),
        .out    (out_node)
    );

    assign out = out_node;
    assign adder = in + g * out_node;

    // always_ff @( posedge sample_clk ) begin
    //     counter <= counter + 1;
    //     $display("[comb_filter] t = %d, c = %d, in = %f, adder = %f, out = %f", t, counter, $itor(in*`SF), $itor(adder*`SF), $itor(out*`SF));
    // end

    /* Set configuration values */
    always_ff @(posedge write) begin
        /* Clocked by sample_clk (48kHz): tau = 1 -> 0.02083 ms delay
        For a delay of 30 ms, set tau = 1440.  */
        t <= tau;   // TODO: Properly configure length from delay value
        g <= gain;
    end
endmodule