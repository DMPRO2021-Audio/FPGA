`timescale 1ns / 1ps

`include "constants.svh"

`define MIN_FREQUENCY 16
`define MAX_AMPLITUDE ((1 << WIDTH) - 1)
`define MAX_SAMPLES_PER_PERIOD `SAMPLE_RATE / `MIN_FREQUENCY
`define MAX_VOLUME ((1 << 32) - 1)

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
    input logic [15:0] freq,              // Frequency of the oscillator in Hz
    input envelope_t [0:`ENVELOPE_LEN-1] envelopes,

    input logic [WIDTH-1:0] amplitude,
    input wave_shape shape,

    output logic [WIDTH-1:0] out
);

    logic [31:0] volume = 0;
    logic[$clog2(`SAMPLE_RATE):0] sample_index = 0;
    
    logic[WIDTH*2-1:0] out_val = 0;
    assign out = ((out_val * amplitude * volume) / `MAX_AMPLITUDE); // TODO: It might just work to use >> 24 instead of dividing

    // This lookuptable contains the sin values at the maximum amplitude
    // to maintain as much detail as possible in the sample
    logic [WIDTH-1:0] sin_lut [`MAX_SAMPLES_PER_PERIOD - 1:0];
    initial $readmemh("../lookup_tables/sin_lut.txt", sin_lut);

    logic [31:0] duration_in_step = 0;  // Number of ms in the current duration
    logic [$clog2(`ENVELOPE_LEN - 1) - 1:0] envelope_step = 0;

    always_ff @ (posedge(clk)) begin

        if(enable) begin

            sample_index <= (sample_index + freq) % `SAMPLE_RATE;

            case(shape)
                SAWTOOTH: begin
                    out_val <= (`MAX_AMPLITUDE / `SAMPLE_RATE) * sample_index;
                end
                SQUARE: begin
                    out_val <= sample_index > (`SAMPLE_RATE >> 1) ? 0 : `MAX_AMPLITUDE;
                end
                SIN: begin
                    out_val <= sin_lut[sample_index >> 4]; // >> 4 is dividing by MIN_FREQUENCY
                end
                SAMPLE_NAME: begin
                    out_val <= 0;
                end
            endcase

            // Reset the envelope based on command bits
            if(cmds[`ENVELOPE_RESET_BIT]) begin
                envelope_step <= 0;
                duration_in_step <= 0;
            end else begin  
                duration_in_step <= duration_in_step + 1;
                if(duration_in_step >= envelopes[envelope_step].duration) begin
                    if(envelope_step + 1 < `ENVELOPE_LEN) begin
                        envelope_step <= envelope_step + 1;
                    end
                    duration_in_step <= 0;
                end
            end

            if(envelope_step < `ENVELOPE_LEN - 1) begin
                
                // This is done to not divide a negative number which would not
                // work as rate is not set as a signed value
                if(envelopes[envelope_step + 1].rate < envelopes[envelope_step].rate) begin
                    volume <= envelopes[envelope_step].rate - duration_in_step * (envelopes[envelope_step].rate - envelopes[envelope_step + 1].rate) / envelopes[envelope_step].duration;
                end else begin
                    volume <= envelopes[envelope_step].rate + duration_in_step * (envelopes[envelope_step + 1].rate - envelopes[envelope_step].rate) / envelopes[envelope_step].duration;
                end

            end

        end else begin
            out_val <= 0;
            sample_index <= 0; 
        end
    end
endmodule
