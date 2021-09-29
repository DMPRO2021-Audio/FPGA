`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.09.2021 13:11:27
// Design Name: 
// Module Name: DigitalOscillator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "constants.svh"

`define MIN_FREQUENCY 20
`define SAMPLES_PER_PERIOD(FREQ) `SAMPLE_RATE / FREQ
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
    input clk,                  // Assuming sample frequency of 44.1 Khz
    input enable,               // Generate audio signal, else output is 0
    input [15:0] freq,          // Frequency of the oscillator in Hz
    input [WIDTH-1:0] amplitude,
    input wave_shape shape,

    output [WIDTH-1:0] out
);

    reg[12:0] phase = 0;
    reg[WIDTH-1:0] out_val = 0;
    assign out = out_val;

    reg [WIDTH * 2 -1:0] sin_lut [`MAX_SAMPLES_PER_PERIOD - 1:0];

    // This lookuptable contains the sin values at the maximum amplitude
    // to maintain as much  detail as possible in the sample
    initial $readmemh("sin_lut.txt", sin_lut);

    always @ (posedge(clk)) begin

        //$display("SHAPE = %s", shape.name());

        if(enable) begin
            // 44100 / freq = Samples per period
            phase <= (phase + 1) % (`SAMPLES_PER_PERIOD(freq));

            case(shape)
                SAWTOOTH: begin
                    out_val <= phase * amplitude * freq / `SAMPLE_RATE;
                end
                SQUARE: begin
                    out_val <= phase * 2 > `SAMPLES_PER_PERIOD(freq) ? 0 : amplitude;
                end
                SIN: begin
                    out_val <= (sin_lut[phase * (freq / `MIN_FREQUENCY)] * amplitude) >> WIDTH;
                end
                SAMPLE_NAME: begin
                    out_val <= 0;
                end
            endcase
        end else begin
            out_val <= 0;
        end

        $display("%d", out_val);
    end
endmodule
