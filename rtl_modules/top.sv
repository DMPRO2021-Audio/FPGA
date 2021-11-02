`timescale 1ns / 1ps
// Top level module
//

`include "constants.svh"

import protocol_pkg::*;
import shape_pkg::*;

`define MAX_AMP ((1 << 22) - 1)

// Assign pins and instantiate design
module top(
    input logic CLK100MHZ,

    input logic ck_mosi, ck_sck, ck_ss,     // SPI
    output logic ck_miso,                   // SPI

    input logic [3:0] btn,

    (* mark_debug="true" *) output logic [3:0] led,
    output logic [3:0] led_r, led_g, led_b,
    output logic [3:0] jb                   // Output to DAC
);
    /* Declare variables */

    /* Note values C3 to B5 */
    integer n[50];
    initial n = '{
        `REAL_TO_FIXED_POINT(65.406),   // C2       0
        `REAL_TO_FIXED_POINT(69.296),   // C#/Db2
        `REAL_TO_FIXED_POINT(73.416),   // D2
        `REAL_TO_FIXED_POINT(77.782),   // D#/Eb2
        `REAL_TO_FIXED_POINT(82.407),   // E2
        `REAL_TO_FIXED_POINT(87.307),   // F2
        `REAL_TO_FIXED_POINT(92.499),   // F#/Gb2
        `REAL_TO_FIXED_POINT(97.999),   // G2
        `REAL_TO_FIXED_POINT(103.826),  // G#/Ab2
        `REAL_TO_FIXED_POINT(110.000),  // A2
        `REAL_TO_FIXED_POINT(116.541),  // A#/Bb2
        `REAL_TO_FIXED_POINT(123.471),  // B2

        `REAL_TO_FIXED_POINT(130.813),  // C3       12
        `REAL_TO_FIXED_POINT(138.591),  // C#/Db3
        `REAL_TO_FIXED_POINT(146.832),  // D3
        `REAL_TO_FIXED_POINT(155.563),  // D#/Eb3
        `REAL_TO_FIXED_POINT(164.814),  // E3
        `REAL_TO_FIXED_POINT(174.614),  // F3
        `REAL_TO_FIXED_POINT(184.997),  // F#/Gb3
        `REAL_TO_FIXED_POINT(195.998),  // G3
        `REAL_TO_FIXED_POINT(207.652),  // G#/Ab3
        `REAL_TO_FIXED_POINT(220.000),  // A3
        `REAL_TO_FIXED_POINT(233.082),  // A#/Bb3
        `REAL_TO_FIXED_POINT(246.942),  // B3

        `REAL_TO_FIXED_POINT(261.626),  // C4       24
        `REAL_TO_FIXED_POINT(277.183),  // C#/Db4
        `REAL_TO_FIXED_POINT(293.665),  // D4
        `REAL_TO_FIXED_POINT(311.127),  // D#/Eb4
        `REAL_TO_FIXED_POINT(329.628),  // E4
        `REAL_TO_FIXED_POINT(349.228),  // F4
        `REAL_TO_FIXED_POINT(369.994),  // F#/Gb4
        `REAL_TO_FIXED_POINT(391.995),  // G4
        `REAL_TO_FIXED_POINT(415.305),  // G#/Ab4
        `REAL_TO_FIXED_POINT(440.000),  // A4
        `REAL_TO_FIXED_POINT(466.164),  // A#/Bb4
        `REAL_TO_FIXED_POINT(493.883),  // B4

        `REAL_TO_FIXED_POINT(523.251),  // C5       36
        `REAL_TO_FIXED_POINT(554.365),  // C#/Db5
        `REAL_TO_FIXED_POINT(587.330),  // D5
        `REAL_TO_FIXED_POINT(622.254),  // D#/Eb5
        `REAL_TO_FIXED_POINT(659.255),  // E5
        `REAL_TO_FIXED_POINT(698.456),  // F5
        `REAL_TO_FIXED_POINT(739.989),  // F#/Gb5
        `REAL_TO_FIXED_POINT(783.991),  // G5
        `REAL_TO_FIXED_POINT(830.609),  // G#/Ab5
        `REAL_TO_FIXED_POINT(880.000),  // A5
        `REAL_TO_FIXED_POINT(932.328),  // A#/Bb5
        `REAL_TO_FIXED_POINT(987.767),  // B5

        `REAL_TO_FIXED_POINT(1046.502), // C6       48
        `REAL_TO_FIXED_POINT(0.00000)   //
    };


    logic clk;                          // Main internal clock
    logic sample_clk;                   // Clock at the sampling frequency
    logic dac_bit_clk;                  // Serial data clock for the dac-transmitter
    logic sys_clk;                      // DAC System clock of the DAC ~18MHz
    logic lrclk;                        // DAC LR select
    logic sclk;                         // DAC serial clock/bit clock/data clock out
    logic sd;                           // DAC serial data

    logic rstn;
    logic[`SPI_WIDTH-1:0] recv;         // Receiving register
    logic[3:0] led_val = 15;            // Just an initial value: all leds on
    logic[`SPI_WIDTH-1:0] send;         // Dummy send register (functionality not yet implemented
    logic ck_sck_reg;
    logic output_valid;

    assign clk = CLK100MHZ;             // Rename clock

    initial sample_clk <= 0;
    initial dac_bit_clk <= 0;

    // Mapping the leds to the upper part of the wave
    // This is only used for debugging and to show that the wave is generated
    logic signed [23:0] wave;
    // assign led = {
    //     wave >= 7 * (`MAX_AMP >> 3),
    //     wave >= 6 * (`MAX_AMP >> 3),
    //     wave >= 5 * (`MAX_AMP >> 3),
    //     wave >= 4 * (`MAX_AMP >> 3)
    // };
    assign led_r[3] = btn[0];
    assign led_r[2] = output_valid;
    assign led_r[1] = ck_sck_reg;
    assign led_b[0] = ~ck_ss | btn[0];  // Turn on when receiving

    logic [31:0] volume;
    logic [31:0] reverb;
    wavegen_t wave_gens[`N_OSCILLATORS];

    // Sending to oscillator
    wavegen_t wave_gen;
    initial begin
    wave_gen.velocity = 200;
    wave_gen.shape = PIANO;
    wave_gen.cmds = 0 << `ENVELOPE_RESET_BIT | 1 << `WAVEGEN_ENABLE_BIT;

    wave_gen.envelopes[0].gain = 0;
    wave_gen.envelopes[0].duration = 1200;

    wave_gen.envelopes[1].gain = 20;
    wave_gen.envelopes[1].duration = 1200;

    wave_gen.envelopes[2].gain = 40;
    wave_gen.envelopes[2].duration = 1200;

    wave_gen.envelopes[3].gain = 30;
    wave_gen.envelopes[3].duration = 2400;

    wave_gen.envelopes[4].gain = 30;
    wave_gen.envelopes[4].duration = 4800;

    wave_gen.envelopes[5].gain = 10;
    wave_gen.envelopes[5].duration = 4800;

    wave_gen.envelopes[6].gain = 10;
    wave_gen.envelopes[6].duration = 3 * 9600;

    wave_gen.envelopes[7].gain = 0;
    wave_gen.envelopes[7].duration = 4800;
    end

    /* Sample tunes */

    /* Start 'Tilbake til Normalen' monotonic */
    integer tbt_normalen_pitch[54] = '{28, 29, 31, 31, 33, 28, 24, 24, 21, 21, 24, 24, 26, 27, 26, 24, 31, 31, 31, 33, 34, 33, 34, 33, 31, 48, 28, 29, 31, 31, 31, 33, 28, 24, 24, 21, 21, 24, 24, 26, 27, 26, 24, 24, 29, 29, 29, 31, 28, 24, 24, 21, 24, 48};
    // length in 8ths
    integer tbt_normalen_len[54]   = '{1,  1,  2,  1,  1,  1,  1,  1, 1, 1,  1,  1,  1,  1,  1,  2,  1,  1,  1,  1,  1,  1,  1,  1,  2,  4,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, 1, 1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, 4,  4 };
    integer tbt_normalen_tempo = 116 * 2; // 116 bpm to 8ths
    initial wave_gen[0].freq = tbt_normalen_pitch[0];
    // /* End 'Tilbake til Normalen' monotonic */

    integer counter = 0;
    integer idx = 0;
    integer tones[4] = '{12, 16, 19, 16};
    always @(posedge sample_clk) begin
        if (counter >= (`SAMPLE_RATE * 60 / tbt_normalen_tempo) * tbt_normalen_len[idx]) begin
            counter <= 0;
            idx <= (idx + 1) % 54;
            wave_gen.cmds <= wave_gen.cmds | 1 << `ENVELOPE_RESET_BIT;
        end
        else begin
            wave_gen.cmds <= wave_gen.cmds & ~(1 << `ENVELOPE_RESET_BIT);
            wave_gen.freq <= n[tbt_normalen_pitch[idx]];
            counter <= counter + 1;
        end
    end
    assign led[3:0] = idx[3:0];
    /* End sample tunes */

    logic locked;

    // Placeholders for unused signals
    logic in_placeholder = 1;
    logic out_placeholder;

    /* Instantiate modules */

`ifndef DEBUG
    /* Create correct clock on dev board */
    clk_wiz_dev clk_wiz (
        .clk_in(clk),
        .reset(0),
        .clk_out(sys_clk),
        .locked(locked)
    );
`else
    assign sys_clk = clk;
    assign locked = 1;
`endif

    spi_slave #(.WIDTH(`SPI_WIDTH)) spi0 (
        .mosi(ck_mosi),
        .miso(ck_miso),
        .sclk(ck_sck),
        .clk(sys_clk),
        .csn(ck_ss),
        .recv(recv),
        .send(send),
        .output_valid(output_valid)
    );

    control_unit cu0 (
        .sig_in(recv),
        .clk(sys_clk),
        .enable(output_valid),
        .rstn(in_placeholder),
        .volume(volume),
        .reverb(reverb),
        .wave_gens(wave_gens)
    );

    oscillator #(.WIDTH(24)) oscillator0(
        .clk(sample_clk),
        .enable(locked),
        .cmds(wave_gen.cmds),
        .freq(wave_gen.freq),
        .envelopes(wave_gen.envelopes),
        .amplitude(wave_gen.velocity),
        .shape(SIN),
        .out(wave)
    );
    

    dac_transmitter #(.WIDTH(24)) transmitter0(
        .clk(dac_bit_clk),
        .enable(locked),
        .left_data(wave),
        .right_data(wave),

        .sclk(sclk),   // Serial data clock
        .lrclk(lrclk),  // Left right channel select
        .sd(sd)
    );
    assign jb[0] = sys_clk; // DAC system clock
    assign jb[1] = sclk;    // Serial clock
    assign jb[2] = sd;      // Serial data
    assign jb[3] = lrclk;   // Left right clock
    integer sclk_cnt = 0;
    always_ff @(posedge sclk) begin
        sclk_cnt ++;
        $display("[top] sd = %d, lrclk = %d counter = %d expected value = %x", sd, lrclk, sclk_cnt, wave);
    end

    /* Define always blocks */

    // Assign led values
    always_ff @(posedge clk) begin
        if (output_valid) begin
            //led_val <= recv[3:0];
`ifdef DEBUG
            $display("[top] output_valid=1, recv=%x", recv);
`endif
        end
    end


    /*
        Deriving the sample clock (48 KHz) and
        the dac-transmitter serial data clock (2 * 24 * 48Khz)
        from the DAC system clock (384 * 48KHz)
    */

    logic [7:0] sample_clk_counter = 0;
    logic [2:0] dac_bit_clk_counter = 0;

    always @(posedge sys_clk) begin
        sample_clk_counter <= sample_clk_counter + 1;
        dac_bit_clk_counter <= dac_bit_clk_counter + 1;

        // Dividing the clock frequency by 384
        if(sample_clk_counter >= 191) begin
            sample_clk_counter <= 0;
            sample_clk <= ~sample_clk;
        end

        // Dividing the clock frequency by 8
        if(dac_bit_clk_counter >= 3) begin
            dac_bit_clk_counter <= 0;
            dac_bit_clk <= ~dac_bit_clk;
        end
    end

endmodule