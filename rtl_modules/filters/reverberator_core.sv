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
    // write: configurations are updated on posedge of write
    input logic clk, sample_clk, enable, rstn, write,

    input logic signed [WIDTH+`FIXED_POINT-1:0] tau[`NTAU],  // Array of tau delay values
    input logic signed [WIDTH+`FIXED_POINT-1:0] gain[`NGAIN], // Array of g gain values

    input logic signed [WIDTH+`FIXED_POINT-1:0] in,
    output logic signed[WIDTH+`FIXED_POINT-1:0] out
);
    localparam WORD = WIDTH + `FIXED_POINT;
    logic signed [WORD-1:0] comb_out[`NCOMB] = '{default:0};
    logic signed [WORD-1:0] allp_out[`NALLP] = '{default:0};
    logic signed [WORD-1:0] comb_add;
    logic signed [WORD-1:0] out_reg = 0;
    logic signed [WORD-1:0] in_reg = 0;
    logic init = 0;

    // initial comb_out <= '{default:0};
    // initial allp_out <= '{default:0};

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
                //.write      (write ),
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
        .tau        (tau[0+`NCOMB]),
        .gain       (gain[0+`NCOMB]),
        //.write      (inner_write ),
        .out        (allp_out[0])
    );

    allpass_filter #(
        .WIDTH (WIDTH )
    ) allpass1 (
        .clk (clk),
        .sample_clk (sample_clk),
        .rstn       (rstn  ),
        .in         (allp_out[0]),
        .tau        (tau[1+`NCOMB]),
        .gain       (gain[1+`NCOMB]),
        //.write      (inner_write ),
        .out        (allp_out[1])
    );

    // always_ff @(posedge clk) begin
    //     comb_add[0] <= comb_out[0] + comb_out[1];
    //     comb_add[1] <= comb_out[2] + comb_out[3];
    //     comb_add[2] <= comb_add[0] + comb_add[1];
    // end
    // ^ Instead of this:
    assign comb_add = comb_out[0] + comb_out[1] + comb_out[2] + comb_out[3];

    // Should be safe as `gain < 1.0`
    assign out = out_reg;

    always_ff @( posedge sample_clk ) begin
        if (init) begin
            if (enable) begin
                assert(!$isunknown(in)) else $error("[reverberator_core] Input value was unknown");
                in_reg <= in;
                out_reg <= in + ((gain[6] * allp_out[1]) >>> `FIXED_POINT);
            end
        end
        else begin
            init <= 1;
            in_reg <= 32'h0;
            out_reg <= 0;
        end
        // $strobe("\nin = 0x%x, out = 0x%x", in_reg, out_reg);
    end

    // always_ff @(posedge clk) begin
    //     /* Check valid value before allowing update */
    //     if (write) begin
    //         for (integer i = 0; i < `NGAIN; i++) begin
    //             assert (1'b1 <<< `FIXED_POINT >= gain[i]) 
    //             else   $error("Reverberator gain should be =< 1 but was gain[%d] = %f", i, $itor(gain[i]*`SF));
    //         end
    //         gain7 <= gain[6];
    //     end
    // end

endmodule
//  2^24-1 = 16_777_215
//  2^23-1 = 8388607
//  allp_out[1] = -724_315.292969, in = 176_679.437500, comb_add = 5_367_681.011719, gain[6] = 0.699219,
//  out = in - gain[`NFILT] * allp_out[1] = 