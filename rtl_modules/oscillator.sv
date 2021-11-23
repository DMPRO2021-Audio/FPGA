`timescale 1ns / 1ps

`include "constants.svh"

`define MAX_AMPLITUDE ((1 << (WIDTH + `FIXED_POINT)) - 1)

import shape_pkg::*;
import protocol_pkg::*;

module oscillator 
#(
    WIDTH = 24,
    N_WAVEGENS = `N_OSCILLATORS
)
(
    input logic clk,                      // Clock should be of the same sample frequency
    input logic enable,                   // Generate audio signal, else output is 0
    input logic [7:0] cmds,               // Used to reset envelope
    input logic [31:0] freq,              // Frequency of the oscillator as a fixed point value
    input envelope_t [0:`ENVELOPE_LEN-1] envelopes,
    input logic [WIDTH-1:0] amplitude,
    input wave_shape shape,
    input logic [$clog2(N_WAVEGENS + 1)-1:0] index,

    output logic signed [WIDTH + `FIXED_POINT - 1:0] out,
    output logic enabled 
);

    logic [$clog2(`SAMPLE_RATE / 1000):0] ms_counter [N_WAVEGENS] = '{default: 0};
    logic signed [16:0] envelope_gain [N_WAVEGENS] = '{default: 0};
    logic [31:0] duration_in_step [N_WAVEGENS] = '{default: 0};
    logic [$clog2(`ENVELOPE_LEN - 1) - 1:0] envelope_step [N_WAVEGENS] = '{default: 0};
    logic [$clog2(`SAMPLE_RATE) + `FIXED_POINT:0] sample_index [N_WAVEGENS] = '{default: 0};
    
    logic signed [(WIDTH + `FIXED_POINT)*2-1:0] out_val [N_WAVEGENS] = '{default: 0};
    assign out = (out_val[index] * amplitude * envelope_gain[index]) >>> ((WIDTH-1) + (`FIXED_POINT)); //The bitshift is dividing by the max amplitude
    assign enabled = envelope_gain[index] == 0 ? 0 : 1;

    logic [$clog2(`MAX_SAMPLES_PER_PERIOD * `N_WAVETABLES)-1:0] rom_addr;
    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1:0] rom_data;

    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1:0] samples [N_WAVEGENS]; // Storage for rom_data 

    assign rom_addr = (sample_index[index] >> ($clog2(`MIN_FREQUENCY) + `FIXED_POINT)) + (`MAX_SAMPLES_PER_PERIOD * (shape - 2));
    
    // This ROM contains the sample values at the maximum amplitude
    // to maintain as much detail as possible in the sample
    wave_rom wave_rom(
        .clk(clk),
        .en(enable),
        .addr(rom_addr),
        .data(rom_data)
    );

    always_ff @ (posedge(clk)) begin
        if(index < N_WAVEGENS) begin
            if(!enable) begin
                out_val[index] <= 0;
                sample_index[index] <= 0;
                envelope_gain[index] <= 0;
            end else begin

                //$display("Freq[%d] = %d", index, freq);
                //$strobe("Out_val[%d] = %d",index, out_val[index]);
                
                //$display("Frequency [%d] = %d (%d)", index, freq, freq >> `FIXED_POINT);
                // The sample index is a fixed point value with the fexed point at `FIXED_POINT.
                // This is needed to be able to have decimal frequencies.
                samples[(index - 1) % N_WAVEGENS] <= rom_data;
                sample_index[index] <= (sample_index[index] + freq) % (`SAMPLE_RATE << `FIXED_POINT);   

                case(shape)
                    SAWTOOTH: begin
                        out_val[index] <= ((`MAX_AMPLITUDE / `SAMPLE_RATE) * (sample_index[index] >> `FIXED_POINT)) - (`MAX_AMPLITUDE >> 1);
                    end
                    SQUARE: begin
                        out_val[index] <= (sample_index[index] >> `FIXED_POINT) > (`SAMPLE_RATE >> 1) ? -(`MAX_AMPLITUDE >> 1) : `MAX_AMPLITUDE >> 1;
                    end
                    default: begin
                        out_val[index] <= samples[index];
                    end
                endcase

                if(cmds[`ENVELOPE_RESET_BIT]) begin
                    envelope_step[index] <= 0;
                    duration_in_step[index] <= 0;
                    //envelope_gain[index] <= 0;
                end

                // Downscaling the envelope clock to milliseconds
                ms_counter[index] <= ms_counter[index] + 1;
                if(ms_counter[index] >= 23) begin
                    ms_counter[index] <= 0;
                    
                    if(!cmds[`ENVELOPE_RESET_BIT]) begin
                        duration_in_step[index] <= duration_in_step[index] + 1;
                        if(duration_in_step[index] >= envelopes[envelope_step[index]].duration) begin
                            if(envelope_step[index] + 1 < `ENVELOPE_LEN) begin
                                envelope_step[index] <= envelope_step[index] + 1;
                            end
                            duration_in_step[index] <= 0;
                        end

                        // Clamp the envelope gain within 255 and 0
                        if(envelope_gain[index] + (envelopes[envelope_step[index]].rate) > 65535) begin
                            envelope_gain[index] <= 65535;
                        end else if (envelope_gain[index] + (envelopes[envelope_step[index]].rate) < 0) begin
                            envelope_gain[index] <= 0;
                        end else begin 
                            envelope_gain[index] <= envelope_gain[index] + (envelopes[envelope_step[index]].rate);
                        end
                    end
                end
            end
        end
    end

endmodule
