`timescale 1ns / 1ps

`include "constants.svh"

`define SAMPLE_RATE 48000
`define MIN_FREQUENCY 16
`define MAX_AMPLITUDE ((1 << WIDTH) - 1)
`define MAX_SAMPLES_PER_PERIOD `SAMPLE_RATE / `MIN_FREQUENCY

package shape_pkg;
    typedef enum logic [1:0]{
        SAWTOOTH,       
        SQUARE,         
        SIN,           
        SAMPLE_NAME     // Not implemented, this can be any sample
    } wave_shape;
endpackage

import shape_pkg::*;

module oscillator 
#(
    WIDTH = 24
)
(
    input clk,                  // Clock should be of the sam the  frequency
    input enable,               // Generate audio signal, else output is 0
    input [15:0] freq,          // Frequency of the oscillator in Hz
    input [WIDTH-1:0] amplitude,
    input wave_shape shape,

    output [WIDTH-1:0] out
);

    reg[$clog2(`SAMPLE_RATE):0] sample_index = 0; // The sample is indexed from 0 to MAX_SAMPLES_PER_PERIOD
    reg[WIDTH-1:0] out_val = 0;
    assign out = out_val;

    reg [WIDTH * 2 -1:0] sin_lut [`MAX_SAMPLES_PER_PERIOD - 1:0];

    // This lookuptable contains the sin values at the maximum amplitude
    // to maintain as much detail as possible in the sample
    initial $readmemh("../lookup_tables/sin_lut.txt", sin_lut);

    always @ (posedge(clk)) begin

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
                    out_val <= sin_lut[sample_index >> 4]; // Divide by MIN_FREQUENCY
                end
                SAMPLE_NAME: begin
                    out_val <= 0;
                end
            endcase
        end else begin
            out_val <= 0;
            sample_index <= 0; 
        end

    end
endmodule
