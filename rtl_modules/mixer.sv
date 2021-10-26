`timescale 1ns / 1ps

`include "constants.svh"

module mixer
#(
    WIDTH = `SAMPLE_WIDTH,
    N_WAVEGENS = `N_OSCILLATORS
) 
(
    input logic clk,                                        // Sample clock
    input logic signed [WIDTH + `FIXED_POINT - 1:0] waves [N_WAVEGENS],      // N signals from the N wavegenerators
    input logic signed [31:0] master_volume,                // Master volume
    input logic signed [31:0] num_enabled,                  // Number of wavegenerators which are enabled

    output logic signed [WIDTH + `FIXED_POINT - 1:0] out                     // Output: Sum of the waves
);

logic signed [WIDTH + `FIXED_POINT - 1:0] sum [N_WAVEGENS];
logic signed [(WIDTH + `FIXED_POINT) * 2 - 1:0] scaling = 0;

// This is quite inefficient and the critical path could be reduced 
// by adding the numbers in a tournament/tree style 
generate;
    genvar i;
    assign sum[0] = waves[0];
    for(i = 1; i < N_WAVEGENS; i++) begin
        assign sum[i] = sum[i-1] + waves[i];
    end
endgenerate

always_ff @(posedge clk) begin
    // Sum and multiply with an amplitude coefficient
    scaling <= sum[N_WAVEGENS-1] * master_volume * num_enabled / (num_enabled + 2);
    out <= scaling >>> `FIXED_POINT;
end

endmodule