`timescale 1ns/1ps

`include "constants.svh"
// Metastability?

// Jukse flyt-aritmetikk, med fastsatt presisjon
// Relative størrelser
// Newton-Rapson

// Tenke på: hvor mange sykler per sample

// Garantere en datarate gjennom hele systemet
// Vil kanskje trenge buffere for å jevne ut dersom flere moduler trenger samme ressurs

/*
Reverberator based on Schroeder's proposition, composed of four parallel comb filters followed
by two serial all-pass filters.

    +--------------------------------------------------------------------+
    |                                                                  [add]------ out 
    +-[comb(tau1, g1)]-----+                                             |
    |                      |                                          [mul(g7)]
    +-[comb(tau2, g2)]---+ |                                             |
in -+                    [add]-[all-pass(tau5, g5)]-[all-pass(tau6, g6)]-+
    +-[comb(tau3, g3)]---+ |
    |                      |
    +-[comb(tau4, g4)]-----+

Comb filter is designed this way:

in -[add]-[delay(tau)]-+
    |                  +--out
    +--[mul(g)]--------+

All-pass filter:

    +--[mul(-g)]---------------------------+
    |                                      |
in -+-[add]--[delay(tau)]-+-[mul(1-g^2)]--[add]-- out
       |                  |
       +-----[mul(g)]-----+
*/

`define NCOMB 4                 // Number of parallel comb filters
`define NALLP 2                 // Number of serial all-pass filters
`define NFILT 6                 // Total number of filters
`define NTAU  6                 // Total number of tau values (generally same as n filters)
`define NGAIN 7                 // Total number of gain values (generally n filters + 1)
module reverberator_core #(
    parameter WIDTH    = 24,    // Integer width
    parameter MAXDELAY = `MAX_FILTER_FIFO_LENGTH
) (
    // clk: system clock, ignored.
    // sample_clk: sample clock (48kHz), used for all clocked instances in submodules
    // enable: Enables input/output. If not pressed, output is 0 and input to submodules is 0.
    input logic clk, sample_clk, enable,

    input logic signed [0:5][WIDTH+`FIXED_POINT-1:0] tau,   // Array of tau delay values
    input logic signed [0:6][WIDTH+`FIXED_POINT-1:0] gain, // Array of g gain values

    input logic signed [WIDTH+`FIXED_POINT-1:0] in,
    output logic signed[WIDTH+`FIXED_POINT-1:0] out,
    output logic signed[32*6-1:0] debug
);
    localparam WORD = WIDTH + `FIXED_POINT;
    logic signed [WORD-1:0] comb_out[`NCOMB];// = '{default:0};
    logic signed [WORD-1:0] allp_out[3];// = '{default:0};
    logic signed [WORD*2-1:0] allp_out2, g6inv, in_out;// = '{default:0};
    logic signed [WORD*2-1:0] comb_add;
    logic signed [WORD-1:0] in_reg = 0;
    logic signed [WORD-1:0] out_reg;
    logic signed [WORD-1:0] g6;
    integer init = 0;

    logic [32*6-1:0] cdebugs[6];
    assign debug = cdebugs[0]; //{out_reg, cdebugs[0]};


    generate;
        genvar i;
        for (i = 0; i < `NCOMB; ++i) begin
            /* Initialise comb filters */
            comb_filter #(
                .WIDTH      (WIDTH),
                .MAXLEN     (MAXDELAY)      // As n * 0.02083 ms
            ) comb0 (
                .clk        (clk),          // Ignored
                .sample_clk (sample_clk),
                .in         (in_reg),
                .tau        (tau[i]),
                .gain       (gain[i]),
                .out        (comb_out[i]),
                .debug (cdebugs[i])
            );
        end
    endgenerate

    allpass_filter #(
        .WIDTH      (WIDTH),
        .MAXLEN     (MAXDELAY)
    ) allpass0 (
        .clk        (clk),                  // Ignored
        .sample_clk (sample_clk),
        .in         (comb_add[31:0]),
        .tau        (tau[4]),
        .gain       (gain[4]),
        .out        (allp_out[0])
    );

    allpass_filter #(
        .WIDTH      (WIDTH),
        .MAXLEN     (MAXDELAY)
    ) allpass1 (
        .clk        (clk),                  // Ignored
        .sample_clk (sample_clk),
        .in         (allp_out[0]),
        .tau        (tau[5]),
        .gain       (gain[5]),
        .out        (allp_out[1])
    );

    /* Divide by 4 to avoid clipping */
    assign comb_add = (comb_out[0] + comb_out[1] + comb_out[2] + comb_out[3]) >>> 2;

    assign out = out_reg;

    always_ff @( posedge sample_clk ) begin
        g6 <= gain[6];
        g6inv <= `REAL_TO_FIXED_POINT(1) - gain[6];
        if (init > 64) begin
            if (enable) begin
                in_reg <= in;
                in_out <= (in * (`REAL_TO_FIXED_POINT(1.0)-g6)) >>> `FIXED_POINT;

                assert(!$isunknown(in)) else $error("[reverberator_core] Input value was unknown");
                assert(!$isunknown(out_reg)) else $error("[reverberator_core] Output value was unknown");

                allp_out2 <= g6 * allp_out[1];
                out_reg <= in_out[31:0] + ((allp_out2) >>> `FIXED_POINT);
            end
        end
        else begin
            init <= init + 1;
            in_reg <= 32'h0;
            out_reg <= 0;
        end
    end

endmodule
//  2^24-1 = 16_777_215
//  2^23-1 = 8388607
//  allp_out[1] = -724_315.292969, in = 176_679.437500, comb_add = 5_367_681.011719, gain[6] = 0.699219,
