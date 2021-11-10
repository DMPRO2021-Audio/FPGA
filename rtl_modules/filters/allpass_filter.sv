`timescale 1ns/1ps

`include "constants.svh"

/*  All-pass filter

    Expects values to be given as fixed point real numbers

        +--[mul(-g)]-------------------------------+
        |                                          |
    in -+-[add]--[delay(tau)]-n0-[mul(g2:=1-g^2)]--[add]-- out
           |                   |
           +-----[mul(g)]------+

    # Pseudocode
    loop:
        x = delay.pop()
        delay.push(in + g * x)
        out = (-g) * in + (1-g**2) * x
    
    Updating configurations: tau and gain signals are read and updated on positive
    edge of write signal.
*/
module allpass_filter #(
    parameter WIDTH = 24    // Integer width
) (
    input logic clk, sample_clk, rstn,
    input logic signed [WIDTH+`FIXED_POINT-1:0] in,
    input logic signed [WIDTH+`FIXED_POINT-1:0] tau, gain,
    input logic signed write,

    output logic signed [WIDTH+`FIXED_POINT-1:0] out
);
    localparam WORD = WIDTH + `FIXED_POINT;
    logic signed [WORD-1:0] t, g, g2 = 0, n0 = 0;
    logic signed [(WORD)*2-1:0] add0;
    integer counter = 0;

    assign t = tau;
    assign g = gain;

    fifo_delay_bram #(
        .WIDTH  (WORD  ),
        .MAXLEN (`MAX_FILTER_FIFO_LENGTH )
    ) delay (
        .clk    (clk),
        .sample_clk(sample_clk),
        .rstn   (rstn   ),
        .enable (1'b1 ),
        //.write  (1'b1  ),
        .len    (t      ),
        .in     (add0[31:0]   ),
        .out    (n0    )
    );
    
    assign add0 = in + ((n0 * g) >>> `FIXED_POINT);

    assign out = ((in * (-g)) >>> `FIXED_POINT) + ((n0 * g2)>>>`FIXED_POINT);

    always_ff @(posedge sample_clk) begin
        assert(!$isunknown(in)) else $error("[allpass_filter] Input value was unknown");
        assert(!$isunknown(out)) else $error("[allpass_filter] Output value was unknown");
        // $strobe("[allpass_filter] in = 0x%x, out = 0x%x", in, out);

        g2 <= (`REAL_TO_FIXED_POINT(1.0) - ((gain * gain) >>> `FIXED_POINT));

    end

endmodule