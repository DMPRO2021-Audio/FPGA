`timescale 1ns / 1ps
// Top level module
//

`include "constants.svh"

import protocol_pkg::*;
import shape_pkg::*;

`define MAX_AMP ((1 << 22) - 1)

// Assign pins and instantiate design
module top(
    input logic MASTER_CLK,

    input logic spi_mosi,
    input logic spi_miso,
    input logic spi_cs,
    input logic spi_clk,

    output logic dac_data,           // jb[2]
    output logic dac_sys_clk,        // jb[0]
    output logic dac_lr_clk,         // jb[3]
    output logic dac_bit_clk,        // jb[1]

    input logic [7:0] gpio

`ifdef DEVKIT                       // Ports exclusive to devkit
    ,
    input logic [3:0] btn,
    output logic [3:0] led,
    output logic [3:0] led_r, led_g, led_b
`endif
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

    logic sys_clk;                  // ~18MHz system clock
    logic sample_clk;               // Clock at the sampling frequency
    logic lrclk;                    // DAC LR select
    logic sclk;                     // DAC serial clock/bit clock/data clock out
    logic sd;                       // DAC serial data

    logic rstn;

    logic[`SPI_WIDTH-1:0] spi_recv; // Receiving register
    logic[`SPI_WIDTH-1:0] spi_send; // Dummy send register (functionality not yet implemented
    logic output_valid;

    synth_t synth;                  // Global configurations

`ifndef DEVKIT                      // Dummies when not on devkit
    logic [3:0] btn;
    logic [3:0] led;
    logic [3:0] led_r, led_g, led_b;
`endif

    initial sample_clk <= 0;
    initial sclk <= 0;

    /* Setup global synth varables */
    initial begin
        synth.pan.balance = `REAL_TO_FIXED_POINT(0);
        synth.master_volume = `REAL_TO_FIXED_POINT(1);
    end

    /* Initialize oscillators */
    initial begin
        integer i;

        for(i = 0; i < `N_OSCILLATORS; i++) begin
            synth.wave_gens[i].velocity = 500000;
            synth.wave_gens[i].shape = PIANO;
            synth.wave_gens[i].freq = n[12 + i*2];
            synth.wave_gens[i].cmds = 0 << `ENVELOPE_RESET_BIT | 0 << `WAVEGEN_ENABLE_BIT;

            synth.wave_gens[i].envelopes[0].gain = `REAL_TO_FIXED_POINT(0);
            synth.wave_gens[i].envelopes[0].duration = 1200;

            synth.wave_gens[i].envelopes[1].gain = `REAL_TO_FIXED_POINT(2);
            synth.wave_gens[i].envelopes[1].duration = 1200;

            synth.wave_gens[i].envelopes[2].gain = `REAL_TO_FIXED_POINT(1.5);
            synth.wave_gens[i].envelopes[2].duration = 1200;

            synth.wave_gens[i].envelopes[3].gain = `REAL_TO_FIXED_POINT(1);
            synth.wave_gens[i].envelopes[3].duration = 2400;

            synth.wave_gens[i].envelopes[4].gain = `REAL_TO_FIXED_POINT(1);
            synth.wave_gens[i].envelopes[4].duration = 4800;

            synth.wave_gens[i].envelopes[5].gain = `REAL_TO_FIXED_POINT(0.5);
            synth.wave_gens[i].envelopes[5].duration = 4800;

            synth.wave_gens[i].envelopes[6].gain = `REAL_TO_FIXED_POINT(0.25);
            synth.wave_gens[i].envelopes[6].duration = 3 * 9600;

            synth.wave_gens[i].envelopes[7].gain = `REAL_TO_FIXED_POINT(0);
            synth.wave_gens[i].envelopes[7].duration = 4800;
        end
    end

`ifdef NO_MCU
    /* Sample tunes */

    /* Start 'Tilbake til Normalen' monotonic */
    integer tbt_normalen_pitch[54] = '{28, 29, 31, 31, 33, 28, 24, 24, 21, 21, 24, 24, 26, 27, 26, 24, 31, 31, 31, 33, 34, 33, 34, 33, 31, 48, 28, 29, 31, 31, 31, 33, 28, 24, 24, 21, 21, 24, 24, 26, 27, 26, 24, 24, 29, 29, 29, 31, 28, 24, 24, 21, 24, 48};
    // length in 8ths
    integer tbt_normalen_len[54]   = '{1,  1,  2,  1,  1,  1,  1,  1, 1, 1,  1,  1,  1,  1,  1,  2,  1,  1,  1,  1,  1,  1,  1,  1,  2,  4,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, 1, 1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, 4,  4 };
    integer tbt_normalen_tempo = 116 * 2; // 116 bpm to 8ths
    initial wave_gen[0].freq = tbt_normalen_pitch[0];
    /* End 'Tilbake til Normalen' monotonic */

    integer counter = 0;
    integer idx = 0;
    integer tones[4] = '{12, 16, 19, 16};
    always @(posedge sample_clk) begin
        if (counter >= (`SAMPLE_RATE * 60 / tbt_normalen_tempo) * tbt_normalen_len[idx]) begin
            counter <= 0;
            idx <= (idx + 1) % 54;
            synth.wave_gens[0].cmds <= wave_gen.cmds | 1 << `ENVELOPE_RESET_BIT;
            synth.wave_gens[1].cmds <= wave_gen.cmds | 1 << `ENVELOPE_RESET_BIT;
        end
        else begin
            synth.wave_gens[0].cmds <= wave_gen.cmds & ~(1 << `ENVELOPE_RESET_BIT);
            synth.wave_gens[1].cmds <= wave_gen.cmds & ~(1 << `ENVELOPE_RESET_BIT);
            synth.wave_gens[0].freq <= n[tbt_normalen_pitch[idx]];
            synth.wave_gens[1].freq <= n[tbt_normalen_pitch[idx] + 4];
            counter <= counter + 1;
        end
    end
    /* End sample tunes */
`endif

`ifdef DEVKIT
    // Enable panning by holding btn3 or btn2 and pressing btn1
    logic signed [31:0] lr_weight = `REAL_TO_FIXED_POINT(0);
    always_ff @(posedge btn[1]) begin
        if(btn[3] && lr_weight > `REAL_TO_FIXED_POINT(-1.0)) begin
            lr_weight <= lr_weight + `REAL_TO_FIXED_POINT(-0.1);
        end else if(btn[2] && lr_weight < `REAL_TO_FIXED_POINT(1.0)) begin
            lr_weight <= lr_weight + `REAL_TO_FIXED_POINT(0.1);
        end
    end
`endif

    logic locked;

    // Placeholders for unused signals
    logic in_placeholder = 1;
    logic out_placeholder;

    /* Instantiate modules */

`ifndef DEBUG
    /* Create correct clock on dev board */
    clk_wiz clk_wiz (
        .clk_in(MASTER_CLK),
        .reset(0),
        .clk_out(sys_clk),
        .locked(locked)
    );
`else
    assign sys_clk = MASTER_CLK;
    assign locked = 1;
`endif


    /* SPI transmission from MCU */

    spi_slave #(.WIDTH(`SPI_WIDTH)) spi0 (
        .mosi(spi_mosi),
        .miso(spi_miso),
        .sclk(spi_clk),
        .clk(sys_clk),
        .csn(spi_cs),
        .recv(spi_recv),
        .send(spi_send),
        .output_valid(output_valid)
    );


    /* Control unit - Interpret received signal */

    control_unit cu0 (
        .sig_in(spi_recv),
        .clk(sys_clk),
        .enable(output_valid),
        .rstn(1'b1),
        .volume(synth.master_volume),
        .reverb(synth.reverb),// TODO: fix
        .wave_gens(synth.wave_gens)
    );


    /* Oscillators - Wave generation start */

    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1:0] waves [`N_OSCILLATORS];

    generate;
        genvar i;

        for(i = 0; i < `N_OSCILLATORS; i++) begin
            oscillator #(.WIDTH(`SAMPLE_WIDTH)) oscillator(
                .clk(sample_clk),
                .enable(synth.wave_gens[i].cmds[`WAVEGEN_ENABLE_BIT]),
                .cmds(synth.wave_gens[i].cmds), 
                .freq(synth.wave_gens[i].freq),
                .envelopes(synth.wave_gens[i].envelopes),
                .amplitude(24'(synth.wave_gens[i].velocity)),
                .shape(synth.wave_gens[i].shape),
                .out(waves[i])
            );
        end

    endgenerate


    /* Mixer */

    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1:0] mixer_out;
    logic signed [31:0] num_enabled;

    mixer #(
        .WIDTH(`SAMPLE_WIDTH),
        .N_WAVEGENS(`N_OSCILLATORS)
    ) mixer(
        .clk(sample_clk),
        .waves(waves),
        .master_volume(synth.master_volume),
        .num_enabled(num_enabled),
        
        .out(mixer_out)
    );


    /* Reverb */


    /* Pan */

    logic signed [`SAMPLE_WIDTH + `FIXED_POINT-1: 0] left;
    logic signed [`SAMPLE_WIDTH + `FIXED_POINT-1: 0] right;

    pan #(.WIDTH(24)) pan(
        .clk(sample_clk),
        .in(mixer_out),
        .lr_weight(synth.pan.balance),

        .left(left),
        .right(right)
    );

    /* DAC transmission - LAST STAGE */

    dac_transmitter #(.WIDTH(`SAMPLE_WIDTH)) transmitter0(
        .clk(sclk),
        .enable(locked),
        .left_data(`FIXED_POINT_TO_SAMPLE_WIDTH(left)),
        .right_data(`FIXED_POINT_TO_SAMPLE_WIDTH(right)),

        .lrclk(lrclk),  // Left right channel select
        .sd(sd)
    );

    assign dac_sys_clk = sys_clk; // DAC system clock
    assign dac_bit_clk = sclk;    // Serial clock
    assign dac_data = sd;      // Serial data
    assign dac_lr_clk = lrclk;   // Left right clock


    /* Define always blocks */


    /*
        Deriving the sample clock (48 KHz) and
        the dac-transmitter serial data clock (2 * 24 * 48Khz)
        from the DAC system clock (384 * 48KHz)
    */

    logic [7:0] sample_clk_counter = 0;
    logic [2:0] sclk_counter = 0;

    always @(posedge sys_clk) begin
        sample_clk_counter <= sample_clk_counter + 1;
        sclk_counter <= sclk_counter + 1;

        // Dividing the clock frequency by 384
        if(sample_clk_counter >= 191) begin
            sample_clk_counter <= 0;
            sample_clk <= ~sample_clk;
        end

        // Dividing the clock frequency by 8
        if(sclk_counter >= 3) begin
            sclk_counter <= 0;
            sclk <= ~sclk;
        end
    end

    logic [$clog2(`N_OSCILLATORS):0] num_enabled_count[`N_OSCILLATORS];
    // Count enabled oscillators
    generate;
        //genvar i;
        assign num_enabled_count[0] = synth.wave_gens[0].cmds[`WAVEGEN_ENABLE_BIT];
        for (i = 1; i < `N_OSCILLATORS; i++) begin
            assign num_enabled_count[i] = num_enabled_count[i-1] + synth.wave_gens[i].cmds[`WAVEGEN_ENABLE_BIT];
        end
    endgenerate
    always_ff @(posedge sys_clk) begin
        num_enabled <= num_enabled_count[`N_OSCILLATORS-1];
    end
    
    logic [2:0] btn_pressed;
    always_ff @(posedge sys_clk) begin
        for (integer j = 0; j < 3; j++) begin
            if (gpio[j] == 1) begin
                synth.wave_gens[j].cmds[`WAVEGEN_ENABLE_BIT] <= 1;
                synth.wave_gens[j].cmds[`ENVELOPE_RESET_BIT] <= ~btn_pressed[j];
                btn_pressed[j] <= 1;
            end
            else begin
                synth.wave_gens[j].cmds[`WAVEGEN_ENABLE_BIT] <= 0;
                btn_pressed[j] <= 0;
            end
        end // endfor
    
    end

endmodule