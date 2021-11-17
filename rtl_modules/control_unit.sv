`timescale 1ns / 1ps

`include "constants.svh"

import protocol_pkg::*;
import shape_pkg::*;

//-------------------------------------------------------------------------------------------------/
// TODO: Integrate SPI slave
// Control unit for FPGA, handles commands from MCU, stores configuration values and controls
// effect modules.
// 
// ## When enable signal is activated
// Clock in config struct, WIDTH bits at the time
//
// Might add some on-demand feedback to mcu later?
//-------------------------------------------------------------------------------------------------/


module control_unit (
    /* SPI */
    input logic spi_mosi,
    input logic spi_clk,
    input logic spi_csn,
    output logic spi_miso,
    /* clocks */
    input logic clk, sample_clk,
    /* outputs to system */
    output synth_t synth,
    output logic [8:0] debug
);
    /* SPI details:
    SPI csn is triggered before starting the clock, and the clock stops before csn is released. Data
    is read from mosi soon as the clock starts running. Time from clock stop to csn released is
    about 30us.

    MIDI is a relatively slow protocol, a quick burst test yielded a minimal gap between SPI
    messages at abou 8.5ms. Using a system clock at 18.43 MHz (T ~= 54ns), we should be able to
    safely interpret the message on csn release. Sample clock is at 48kHz (T ~= 20.8us), meaning
    2-3 messages may come between two samples.
    */

    synth_t input_buffer;
    logic [1:0] dirty_bit = 0;

    // TODO [possible error]: spi_clk stops when signal is completely sent, stopping the pipeline here
    always_ff @( posedge spi_clk ) begin
        /* Shift in while SPI clock is running ~~and csn is active~~ */
        input_buffer <=  (spi_mosi << ($bits(synth_t)-1)) | (input_buffer >> 1);//input_buffer[0] << 1 | spi_mosi;//

    end

    genvar i, j;

    generate

    for (i = 0; i < `N_OSCILLATORS; i=i+1) begin
        always_ff @( posedge sample_clk ) begin
            if (spi_csn && dirty_bit) begin
                if(dirty_bit == 1) begin
                    synth.wave_gens[i].freq     <= input_buffer[ $bits(wavegen_t)*i+31  : $bits(wavegen_t)*i ];
                    synth.wave_gens[i].velocity <= input_buffer[ $bits(wavegen_t)*i+63 : $bits(wavegen_t)*i+32 ];
                    // ENVELOPE BETWEEN THESE
                    synth.wave_gens[i].shape <= wave_shape'(input_buffer[$bits(wavegen_t)*i+64+$bits(envelope_t) * `ENVELOPE_LEN+7  : $bits(wavegen_t)*i+64+$bits(envelope_t)*`ENVELOPE_LEN ]);
                    synth.wave_gens[i].cmds  <=             input_buffer[$bits(wavegen_t)*i+64+$bits(envelope_t) * `ENVELOPE_LEN+15 : $bits(wavegen_t)*i+64+$bits(envelope_t)*`ENVELOPE_LEN+8];
                end else if (dirty_bit == 2 && synth.wave_gens[i].cmds[`ENVELOPE_RESET_BIT]) begin
                    // Remove the envelope reset after one cycle
                    synth.wave_gens[i].cmds <= synth.wave_gens[i].cmds & ~(1 << `ENVELOPE_RESET_BIT);
                end
            end
        end
    end
    for (i = 0; i < `N_OSCILLATORS; i=i+1) begin
        for (j = 0; j < `ENVELOPE_LEN; j=j+1) begin
            always_ff @( posedge sample_clk ) begin
                if (spi_csn && dirty_bit == 1) begin
                    synth.wave_gens[i].envelopes[j].rate     <= input_buffer[ $bits(wavegen_t)*i+64+$bits(envelope_t)*j+7 : $bits(wavegen_t)*i+64+$bits(envelope_t)*j ];
                    synth.wave_gens[i].envelopes[j].duration <= input_buffer[ $bits(wavegen_t)*i+64+$bits(envelope_t)*j+15: $bits(wavegen_t)*i+64+$bits(envelope_t)*j+8 ];
                end
            end
        end
    end
    always_ff @( posedge sample_clk ) begin
        if (spi_csn && dirty_bit) begin

            
            if(dirty_bit == 1) begin
                dirty_bit <= 2;
                /* Nothing is being sent, clear to read */
                /* Hardwire fields */
                synth.master_volume <= input_buffer[$bits(wavegen_t)*`N_OSCILLATORS+31 : $bits(wavegen_t)*`N_OSCILLATORS ];
                synth.reverb.tau <= {
                    input_buffer[ $bits(synth_t)-417 : $bits(synth_t)-448 ],
                    input_buffer[ $bits(synth_t)-385 : $bits(synth_t)-416 ],
                    input_buffer[ $bits(synth_t)-353 : $bits(synth_t)-384 ],
                    input_buffer[ $bits(synth_t)-321 : $bits(synth_t)-352 ],
                    input_buffer[ $bits(synth_t)-289 : $bits(synth_t)-320 ],
                    input_buffer[ $bits(synth_t)-257 : $bits(synth_t)-288 ]
                };
                synth.reverb.gain <= {
                    input_buffer[ $bits(synth_t)-225 : $bits(synth_t)-256 ],
                    input_buffer[ $bits(synth_t)-193 : $bits(synth_t)-224 ],
                    input_buffer[ $bits(synth_t)-161 : $bits(synth_t)-192 ],
                    input_buffer[ $bits(synth_t)-129 : $bits(synth_t)-160 ],
                    input_buffer[ $bits(synth_t)-97  : $bits(synth_t)-128 ],
                    input_buffer[ $bits(synth_t)-65  : $bits(synth_t)-96  ],
                    input_buffer[ $bits(synth_t)-33  : $bits(synth_t)-64  ]
                };
            end else if(dirty_bit == 2) begin
                dirty_bit <= 0;
            end
            synth.pan.balance <= input_buffer[ $bits(synth_t)-1:$bits(synth_t)-32 ];
        end else if(!spi_csn) begin
            dirty_bit <= 1;
        end
    end
    endgenerate

endmodule