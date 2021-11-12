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
    // clk: system clock
    // enable: ignored
    // rstn: propagated/ingnored
    input logic clk, sample_clk, enable, rstn,

    input logic signed [0:5][WIDTH+`FIXED_POINT-1:0] tau,   // Array of tau delay values
    input logic signed [0:6][WIDTH+`FIXED_POINT-1:0] gain, // Array of g gain values

    input logic signed [WIDTH+`FIXED_POINT-1:0] in,
    output logic signed[WIDTH+`FIXED_POINT-1:0] out
);
    localparam WORD = WIDTH + `FIXED_POINT;
    logic signed [WORD-1:0] comb_out[`NCOMB] = '{default:0};
    logic signed [WORD-1:0] allp_out[`NALLP] = '{default:0};
    logic signed [WORD-1:0] comb_add;
    logic signed [WORD-1:0] in_reg = 0;
    logic signed [WORD-1:0] out_reg = 0;
    logic signed [WORD-1:0] g6 = 0;
    logic init = 0;

    initial begin

    end
    generate;
        genvar i;
        for (i = 0; i < `NCOMB; ++i) begin
            /* Initialise comb filters */
            comb_filter #(
                .WIDTH       (WIDTH     ),
                .MAXDELAY   (MAXDELAY )   // As n * 0.02083 ms
            ) comb0 (
                .clk        (clk   ),    // Ignored
                .sample_clk (sample_clk),
                .rstn       (rstn  ),
                .in         (in_reg    ),
                .tau        (tau[i]   ),
                .gain       (gain[i]  ),
                .out        (comb_out[i])
            );
        end
    endgenerate

    allpass_filter #(
        .WIDTH (WIDTH )
    ) allpass0 (
        .clk (clk),
        .sample_clk (sample_clk),
        .rstn       (rstn  ),
        .in         (comb_add),
        .tau        (tau[4]),
        .gain       (gain[4]),
        .out        (allp_out[0])
    );

    allpass_filter #(
        .WIDTH (WIDTH )
    ) allpass1 (
        .clk (clk),
        .sample_clk (sample_clk),
        .rstn       (rstn  ),
        .in         (allp_out[0]),
        .tau        (tau[5]),
        .gain       (gain[5]),
        .out        (allp_out[1])
    );

    assign comb_add = comb_out[0] + comb_out[1] + comb_out[2] + comb_out[3];

    // Should be safe as `gain < 1.0`
    assign out = out_reg;

    always_ff @( posedge sample_clk ) begin
        g6 <= gain[6];
        if (init) begin
            if (enable) begin
                // $display("[reverberator_core] in = %d comb_out = {%d, %d, %d, %d} allp_out = {%d, %d} gain[6] = %d out = %d",
                //         in, comb_out[0], comb_out[1], comb_out[2], comb_out[3], allp_out[0], allp_out[1], gain[6], out_reg);
                assert(!$isunknown(in)) else $error("[reverberator_core] Input value was unknown");
                in_reg <= in;
                out_reg <= in_reg + ((g6 * allp_out[1]) >>> `FIXED_POINT);
            end
        end
        else begin
            init <= 1;
            in_reg <= 32'h0;
            out_reg <= 0;
        end
    end

endmodule
//  2^24-1 = 16_777_215
//  2^23-1 = 8388607
//  allp_out[1] = -724_315.292969, in = 176_679.437500, comb_add = 5_367_681.011719, gain[6] = 0.699219,
