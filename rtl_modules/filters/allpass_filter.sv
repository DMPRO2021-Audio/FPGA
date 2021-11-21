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
    parameter WIDTH = 24,    // Integer width
    parameter MAXLEN = `MAX_FILTER_FIFO_LENGTH,
    parameter MID = 0 // Module ID
) (
    input logic sample_clk,
    input logic signed [WIDTH+`FIXED_POINT-1:0] in,
    input logic signed [WIDTH+`FIXED_POINT-1:0] tau, gain,

    output logic signed [WIDTH+`FIXED_POINT-1:0] out
);
    localparam WORD = WIDTH + `FIXED_POINT;
    logic signed [WORD-1:0] t = 4096, g = 0, g2, n0;
    /* Double width for registers targeted by multiplications */
    logic signed [(WORD)*2-1:0] add0 = 0, out_reg = 0, g2_calc = 0;
    integer counter;
    logic init = 0;

    // assign t = tau;
    // assign g = gain;

    initial $display("[allpass_filter] tau = %d gain = %d", tau, gain);

    fifo_delay_bram #(
        .WIDTH  (WORD  ),
        .MAXLEN (MAXLEN )
    ) delay (
        .sample_clk(sample_clk),
        .enable (1'b1 ),
        .len    (t      ),
        .in     (add0[31:0]   ),
        .out    (n0    )
    );

    //assign add0 = in + ((n0 * g) >>> `FIXED_POINT);

    //assign out = ((in * (-g)) >>> `FIXED_POINT) + ((n0 * g2)>>>`FIXED_POINT);
    assign out = out_reg[31:0];
    assign g2 = g2_calc[31:0];

    always_ff @(posedge sample_clk) begin
        g2_calc <= (`REAL_TO_FIXED_POINT(1.0) - ((gain * gain) >>> `FIXED_POINT));
        t <= tau;
        g <= gain;
        if (init) begin
            assert(!$isunknown(in)) else $error("[allpass_filter] Input value was unknown");
            assert(!$isunknown(out)) else $error("[allpass_filter] Output value was unknown");
            // $strobe("[allpass_filter] in = 0x%x, out = 0x%x", in, out);
            add0 <= in + ((n0 * g) >>> `FIXED_POINT);
            out_reg <= ((in * (-g)) >>> `FIXED_POINT) + ((n0 * g2)>>>`FIXED_POINT);

        end
        else begin
            init <= init + 1;
            add0 <= 32'h0;
            out_reg <= 32'h0;
        end
    end

endmodule