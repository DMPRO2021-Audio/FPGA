`timescale 1ns / 1ps

module mixer
#(
    WIDTH = 24,
    N_WAVEGENS = `N_OSCILLATORS
) 
(
    input logic clk,                                        // Sample clock
    input logic signed [WIDTH-1:0] waves [N_WAVEGENS],      // N signals from the N wavegenerators
    input logic signed [31:0] master_volume,                // Master volume
    input logic signed [31:0] num_enabled,                  // Number of wavegenerators which are enabled

    output logic signed [WIDTH-1:0] out                     // Output: Sum of the waves
);

logic signed [WIDTH-1:0] sum = 0;
logic signed [WIDTH*2 - 1:0] scaling = 0;

always_ff @(posedge clk) begin
    // Sum and multiply with an amplitude coefficient
    sum <= waves.sum();
    scaling <= sum * master_volume * num_enabled / (num_enabled + 2);
    out <= scaling >>> `VOLUME_FIXED_POINT;
end

endmodule