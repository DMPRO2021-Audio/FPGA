`timescale 1ns / 1ps

`include "constants.svh"

/*
    This module uses the constant power pan-rule
    thus g_l^2 + g_r^2 = 1. Where g_l and g_r are left and right gain respectivly
    The rule is described here: http://rs-met.com/documents/tutorials/PanRules.pdf
    to fullfill the rule, the gain value is calculated using sine and cosine values.
*/

`define LUT_SIZE `MAX_SAMPLES_PER_PERIOD    

module pan 
#(
    WIDTH = `SAMPLE_WIDTH
)
(
    input logic clk,
    input logic signed [WIDTH + `FIXED_POINT - 1: 0] in,
    input logic signed [31:0] lr_weight, // 0 is equal weighting and negative is left and positive is right

    output logic signed [WIDTH + `FIXED_POINT - 1: 0] left,
    output logic signed [WIDTH + `FIXED_POINT - 1: 0] right
);

// This lookuptable contains the sin values at the maximum amplitude to keep detail and thus needs to be left shifted
// The sine values can be used to find the cos values at an offset Sin(x) = Cos((PI / 2) - x)
logic signed [WIDTH + `FIXED_POINT - 1:0] sin_lut [`LUT_SIZE:0];
initial $readmemh("./lookup_tables/sin_lut.txt", sin_lut);

logic signed [WIDTH + `FIXED_POINT - 1:0] gain_left;
logic signed [WIDTH + `FIXED_POINT - 1:0] gain_right;
logic signed [2 * (WIDTH + `FIXED_POINT) - 1:0] scaled_left;
logic signed [2 * (WIDTH + `FIXED_POINT) - 1:0] scaled_right;
logic signed [31:0] theta;  // Offset within the sine wave

assign left = scaled_left >>> (WIDTH + `FIXED_POINT - 1);
assign right = scaled_right >>> (WIDTH + `FIXED_POINT - 1);

always_ff @(posedge clk) begin
    // Theta = PI * (1 + lr_weight) / 4 = (PI + PI * lr_weight) / 4
    theta <= (`LUT_SIZE + ((`LUT_SIZE * lr_weight) >>> `FIXED_POINT)) >>> 3;

    // LUT_SIZE corresponds to 2*PI and thus `LUT_SIZE >> 2 is PI/2
    gain_left <= sin_lut[(`LUT_SIZE >> 2) - theta];
    gain_right <= sin_lut[theta];

    // Since we dont want to reduce the original signal, we shift by one less
    scaled_left <= (in * gain_left);
    scaled_right <= (in * gain_right);
end

endmodule