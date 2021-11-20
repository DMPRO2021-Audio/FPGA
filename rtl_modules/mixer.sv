`timescale 1ns / 1ps

`include "constants.svh"    

module mixer
#(
    WIDTH = `SAMPLE_WIDTH,
    N_WAVEGENS = `N_OSCILLATORS
) 
(
    input logic sys_clk,                                    // System clock
    input logic sample_clk,                                 // Sample clock
    input logic signed [WIDTH + `FIXED_POINT - 1:0] wave,   // Wave signal from the oscillator
    input logic signed [31:0] master_volume,                // Master volume
    input logic enabled,                                    // Control signal from the oscillator indicating that it is making waves 
    input logic [$clog2(N_WAVEGENS+1)-1:0] index,           // Index of the current oscillator
    input logic [8:0] clk_counter,


    output logic signed [WIDTH + `FIXED_POINT - 1:0] out    // Output: Sum of the waves adjusted with master volume and amplitude coefficient
);

logic signed [WIDTH + `FIXED_POINT + $clog2(N_WAVEGENS):0] accumulator = 0; // Accumulater with room for overflow
logic signed [WIDTH + `FIXED_POINT + $clog2(N_WAVEGENS) + `FIXED_POINT:0] sum = 0;
logic signed [$clog2(N_WAVEGENS) + 1:0] num_enabled = 0;

always_ff @(posedge sys_clk) begin
    if(clk_counter < N_WAVEGENS) begin
        accumulator <= accumulator + wave;
        num_enabled <= num_enabled + enabled;

        //$strobe("Accumulator = %d", accumulator);
        //$strobe("N_enabled = %d", num_enabled);
    end

    if(clk_counter == N_WAVEGENS) begin
        sum <= accumulator * master_volume * num_enabled / (num_enabled + 2) >>> `FIXED_POINT;
        //$strobe("SUM = %d", sum);
    end

    if(clk_counter >= 383) begin
        accumulator <= 0;
        num_enabled <= 0;
    end
end

always_ff @(posedge sample_clk) begin
    // Clamp the output to avoid clipping
    if(sum > int'((1 << (WIDTH + `FIXED_POINT - 1)) - 1)) begin
        out <= 1 << (WIDTH + `FIXED_POINT - 1) - 1;
    end else if (sum < int'(1 << (WIDTH + `FIXED_POINT - 1))) begin
        out <= (1 << (WIDTH + `FIXED_POINT - 1));
    end else begin
        out <= sum;
    end
end

endmodule