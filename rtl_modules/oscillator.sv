`timescale 1ns / 1ps

`include "constants.svh"

`define MAX_AMPLITUDE ((1 << (WIDTH + `FIXED_POINT)) - 1)

import shape_pkg::*;
import protocol_pkg::*;

module oscillator 
#(
    WIDTH = 24
)
(
    input logic clk,                      // Clock should be of the same sample frequency
    input logic enable,                   // Generate audio signal, else output is 0
    input logic [7:0] cmds,               // Used to reset envelope
    input logic [31:0] freq,              // Frequency of the oscillator as a fixed point value
    input envelope_t [0:`ENVELOPE_LEN-1] envelopes,
    input logic [WIDTH-1:0] amplitude,
    input wave_shape shape,

    output logic signed [WIDTH + `FIXED_POINT - 1:0] out
);

    logic [7:0] envelope_gain = 0;
    logic [31:0] duration_in_step = 0;
    logic [$clog2(`ENVELOPE_LEN - 1) - 1:0] envelope_step = 0;
    logic [$clog2(`SAMPLE_RATE) + `FIXED_POINT:0] sample_index = 0;
    
    logic signed [(WIDTH + `FIXED_POINT)*2-1:0] out_val = 0;
    assign out = (out_val * amplitude * envelope_gain) >>> ((WIDTH-1) + `FIXED_POINT); //The bitshift is dividing by the max amplitude

    logic [$clog2(`MAX_SAMPLES_PER_PERIOD * `N_WAVETABLES)-1:0] rom_addr;
    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1:0] rom_data;
    
    // This ROM contains the sample values at the maximum amplitude
    // to maintain as much detail as possible in the sample
    wave_rom wave_rom(
        .clk(clk),
        .en(enable),
        .addr(rom_addr),
        .data(rom_data)
    );

    always_ff @ (posedge(clk)) begin

        if(enable) begin
            // The sample index is a fixed point value with the fexed point at `FIXED_POINT.
            // This is needed to be able to have decimal frequencies.
            sample_index <= (sample_index + freq) % (`SAMPLE_RATE << `FIXED_POINT);    

            case(shape)
                SAWTOOTH: begin
                    out_val <= ((`MAX_AMPLITUDE / `SAMPLE_RATE) * (sample_index >> `FIXED_POINT)) - (`MAX_AMPLITUDE >> 1);
                end
                SQUARE: begin
                    out_val <= (sample_index >> `FIXED_POINT) > (`SAMPLE_RATE >> 1) ? -(`MAX_AMPLITUDE >> 1) : `MAX_AMPLITUDE >> 1;
                end
                SIN: begin
                    rom_addr <= (sample_index >> ($clog2(`MIN_FREQUENCY) + `FIXED_POINT));       
                    out_val <= rom_data;
                end
                PIANO: begin
                    rom_addr <= (sample_index >> ($clog2(`MIN_FREQUENCY) + `FIXED_POINT)) + 3000;       
                    out_val <= rom_data;
                end
            endcase

            // Reset the envelope based on command bits
            if(cmds[`ENVELOPE_RESET_BIT]) begin
                envelope_step <= 0;
                duration_in_step <= 0;
            end else begin  
                duration_in_step <= duration_in_step + 1;
                if(duration_in_step >= envelopes[envelope_step].duration << `FIXED_POINT) begin
                    if(envelope_step + 1 < `ENVELOPE_LEN) begin
                        $display("GAIN = %d", envelopes[envelope_step].gain);
                        envelope_step <= envelope_step + 1;
                    end
                    duration_in_step <= 0;
                end
            end

            if(envelope_step < `ENVELOPE_LEN - 1) begin
                
                // This is done to not divide a negative number which would not
                // work as rate is not set as a signed value
                if(envelopes[envelope_step + 1].gain < envelopes[envelope_step].gain) begin
                    envelope_gain <= envelopes[envelope_step].gain - duration_in_step * (envelopes[envelope_step].gain - envelopes[envelope_step + 1].gain) / (envelopes[envelope_step].duration << `FIXED_POINT);
                end else begin
                    envelope_gain <= envelopes[envelope_step].gain + duration_in_step * (envelopes[envelope_step + 1].gain - envelopes[envelope_step].gain) / (envelopes[envelope_step].duration << `FIXED_POINT);
                end

            end

        end else begin
            out_val <= 0;
            sample_index <= 0; 
        end
    end
endmodule
