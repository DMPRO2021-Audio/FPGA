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
    output logic spi_miso,
    input logic spi_csn,
    input logic spi_clk,

    output logic dac_data,           // jb[2]
    output logic dac_sys_clk,        // jb[0]
    output logic dac_lr_clk,         // jb[3]
    output logic dac_bit_clk,        // jb[1]

    output logic [7:0] gpio

);
    /* Declare variables */

    logic sys_clk;                  // ~18MHz system clock
    logic sample_clk;               // Clock at the sampling frequency
    logic lrclk;                    // DAC LR select
    logic sclk;                     // DAC serial clock/bit clock/data clock out
    logic sd;                       // DAC serial data

    synth_t synth;                  // Global configurations

    initial sample_clk <= 1;
    initial sclk <= 1;
    initial $display("Size with %d oscillators and %d envelopes of synth_t: %d bits = %d Bytes", `N_OSCILLATORS, `ENVELOPE_LEN, $bits(synth_t), $bits(synth_t) / 8);

`ifdef NODEF
    /* Note values C3 to B5 */
    integer n[62];
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
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000)   //
    };
    /* Setup global synth varables */
    initial begin
        synth.pan.balance = `REAL_TO_FIXED_POINT(0);
        synth.master_volume = `REAL_TO_FIXED_POINT(3);
    end

    /* Initialize oscillators */
    initial begin
        integer i;

        for(i = 0; i < `N_OSCILLATORS; i++) begin
            synth.wave_gens[i].velocity = 0;
            synth.wave_gens[i].shape = SIN;
            synth.wave_gens[i].cmds = 0 << `ENVELOPE_RESET_BIT | 1 << `WAVEGEN_ENABLE_BIT;

            synth.wave_gens[i].envelopes[0].rate = 127;
            synth.wave_gens[i].envelopes[0].duration = 255;

            synth.wave_gens[i].envelopes[1].rate = -20;
            synth.wave_gens[i].envelopes[1].duration = 255;

            synth.wave_gens[i].envelopes[2].rate = -10;
            synth.wave_gens[i].envelopes[2].duration = 100;

            synth.wave_gens[i].envelopes[3].rate = -5;
            synth.wave_gens[i].envelopes[3].duration = 100;

            synth.wave_gens[i].envelopes[4].rate = 0;
            synth.wave_gens[i].envelopes[4].duration = 255;

            synth.wave_gens[i].envelopes[5].rate = 0;
            synth.wave_gens[i].envelopes[5].duration = 255;

            synth.wave_gens[i].envelopes[6].rate = 0;
            synth.wave_gens[i].envelopes[6].duration = 255;

            synth.wave_gens[i].envelopes[7].rate = -2;
            synth.wave_gens[i].envelopes[7].duration = 100;
        end
        synth.wave_gens[0].velocity = 750;
        synth.wave_gens[1].velocity = 700;
        synth.wave_gens[2].velocity = 700;
        synth.wave_gens[3].velocity = 700;
        // synth.wave_gens[0].freq = 440 * 8;
    end

    /* Start 'O bli hos meg' polyphonic */
    integer o_bli_hos_meg_p1[41] = '{31, 31, 29, 27, 34, 36, 34, 34, 32, 31, 31, 32, 34, 36, 34, 32, 29, 31, 33, 34, 31, 31, 29, 27, 34, 34, 32, 32, 31, 29, 29, 31, 32, 31, 29, 27, 32, 31, 29, 27, 61 };
    integer o_bli_hos_meg_l1[41] = '{4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  4,  4,  2,  2,  2,  2,  8 , 4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  2,  2,  2,  2,  4,  4,  4, 4  };
    integer o_bli_hos_meg_p2[41] = '{27, 26, 26, 27, 27, 24, 26, 27, 29, 27, 27, 27, 27, 27, 27, 27, 29, 27, 27, 26, 27, 26, 26, 27, 27, 27, 27, 28, 28, 29, 26, 27, 26, 27, 26, 24, 29, 27, 26, 22, 61 };
    //integer o_bli_hos_meg_l2[40] = '{4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  4,  4,  2,  2,  2,  2,  8 , 4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  2,  2,  2,  2,  4,  4,  8  };

    integer o_bli_hos_meg_p3[43] = '{22, 22, 20, 19, 15, 15, 22, 22, 22, 22, 22, 20, 19, 20, 19, 24, 22, 22, 15, 17, 19, 20, 22, 20, 19, 27, 26, 24, 24, 24, 22, 20, 22, 22, 22, 22, 20, 19, 24, 22, 20, 19, 61 };
    integer o_bli_hos_meg_l3[43] = '{4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  2,  2,  2,  2,  4,  2,  2,  2,  2,  2,  2,  8,  4,  2,  2,  2,  2,  2,  2,  6,  2,  4, 4  };

    integer o_bli_hos_meg_p4[42] = '{15, 10, 10, 12, 7,  8,  10, 12, 14, 15, 15, 14, 12, 10, 8,  15, 17, 14, 15, 12, 10, 15, 10, 10, 12, 7,  8,  10, 12, 12, 17, 20, 19, 17, 15, 10, 12, 8,  10, 10, 15, 61 };
    integer o_bli_hos_meg_l4[42] = '{4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  2,  2,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  4,  4,  3,  1,  2,  2,  8,  4,  2,  2,  2,  2,  2,  2,  4,  4,  4, 4  };
    integer o_bli_hos_meg_tempo = 132;

    integer reverb_testing_p[4] = '{24+12, 61, 31+12, 61};
    integer reverb_testing_l[4] = '{1, 1, 1, 1};
    integer reverb_testing_tempo = 200;

    integer counter1 = 0;
    integer counter2 = 0;
    integer counter3 = 0;
    integer idx1 = 0;
    integer idx2 = 0;
    integer idx3 = 0;
    /* End 'O bli hos meg' polyphonic */
    always @(posedge sample_clk) begin
        // if (counter1 >= (`SAMPLE_RATE * 60 / reverb_testing_tempo) * reverb_testing_l[idx1]) begin
        //     counter1 <= 0;
        //     idx1 <= (idx1 + 1) % 4;
        //     synth.wave_gens[0].cmds <= synth.wave_gens[0].cmds | 1 << `ENVELOPE_RESET_BIT;
        // end
        // else begin
        //     synth.wave_gens[0].cmds <= synth.wave_gens[0].cmds & ~(1 << `ENVELOPE_RESET_BIT);
        //     synth.wave_gens[0].freq <= n[reverb_testing_p[idx1]];
        //     counter1 <= counter1 + 1;
        // end
        if (counter1 >= (`SAMPLE_RATE * 60 / o_bli_hos_meg_tempo) * o_bli_hos_meg_l1[idx1]) begin
            counter1 <= 0;
            idx1 <= (idx1 + 1) % 41;
            synth.wave_gens[0].cmds <= synth.wave_gens[0].cmds | 1 << `ENVELOPE_RESET_BIT;
            synth.wave_gens[1].cmds <= synth.wave_gens[1].cmds | 1 << `ENVELOPE_RESET_BIT;
        end
        else begin
            synth.wave_gens[0].cmds <= synth.wave_gens[0].cmds & ~(1 << `ENVELOPE_RESET_BIT);
            synth.wave_gens[1].cmds <= synth.wave_gens[1].cmds & ~(1 << `ENVELOPE_RESET_BIT);
            synth.wave_gens[0].freq <= n[o_bli_hos_meg_p1[idx1]];
            synth.wave_gens[1].freq <= n[o_bli_hos_meg_p2[idx1]];
            counter1 <= counter1 + 1;
        end
        if (counter2 >= (`SAMPLE_RATE * 60 / o_bli_hos_meg_tempo) * o_bli_hos_meg_l4[idx2]) begin
            counter2 <= 0;
            idx2 <= (idx2 + 1) % 42;
            synth.wave_gens[2].cmds <= synth.wave_gens[2].cmds | 1 << `ENVELOPE_RESET_BIT;
        end
        else begin
            synth.wave_gens[2].cmds <= synth.wave_gens[2].cmds & ~(1 << `ENVELOPE_RESET_BIT);
            synth.wave_gens[2].freq <= n[o_bli_hos_meg_p4[idx2]];
            counter2 <= counter2 + 1;
        end
        if (counter3 >= (`SAMPLE_RATE * 60 / o_bli_hos_meg_tempo) * o_bli_hos_meg_l3[idx3]) begin
            counter3 <= 0;
            idx3 <= (idx3 + 1) % 43;
            synth.wave_gens[3].cmds <= synth.wave_gens[3].cmds | 1 << `ENVELOPE_RESET_BIT;
        end
        else begin
            synth.wave_gens[3].cmds <= synth.wave_gens[3].cmds & ~(1 << `ENVELOPE_RESET_BIT);
            synth.wave_gens[3].freq <= n[o_bli_hos_meg_p3[idx3]];
            counter3 <= counter3 + 1;
        end
    end
    /* End sample tunes */
/////////////
`endif

    /* Instantiate modules */

    integer counter = 0;
    logic half_clk = 0;
    logic quarter_clk = 0;
    logic [32*6-1:0] debug;
    assign gpio[0] = sys_clk;
    assign gpio[3] = sample_clk;
    assign gpio[4] = spi_csn;
    always_ff @( negedge sys_clk ) begin
        if (!sample_clk) begin
            //gpio[1] <= ~spi_csn;
            gpio[1] <= counter <32*6 ? 0 : 1; // csn_out
            //gpio[1] <= counter <$bits(synth_t) ? 0 : 1; // csn_out
            gpio[2] <= counter <32*6 ? debug[counter] : 0;
            //gpio[2] <= counter <$bits(synth_t) ? synth[counter] : 0;
            //gpio[2] <= counter < $bits(synth_t) ? hard[counter] : 0;
            counter <= (counter + 1);// % (32*4 + 32);
        end else begin
            counter <= 0;
            gpio[1] <= 1;
        end
    end

    /* Instantiate modules */

    /* Create correct clock on dev board */
    // logic locked = 1;
    // assign sys_clk = MASTER_CLK;

    clk_wiz clk_wiz (
        .clk_in(MASTER_CLK),
        .reset(0),
        .clk_out(sys_clk),
        .locked(locked)
    );


    /* SPI transmission from MCU */
    /* Control unit - Interpret received signal */

    control_unit u_control_unit (
    	.spi_mosi   (spi_mosi   ),
        .spi_clk    (spi_clk    ),
        .spi_csn    (spi_csn    ),
        .spi_miso   (spi_miso   ),
        .clk        (clk        ),
        .sample_clk (sample_clk ),
        .synth      (synth      )
    );

    /* Oscillators - Wave generation start */

    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1:0] waves [`N_OSCILLATORS];
    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1:0] wave;
    logic [$clog2(`N_OSCILLATORS+1)-1:0] oscillator_index = 0;    // This is incremented at the end of the file

    envelope_t [0:`ENVELOPE_LEN-1] envelopes;
    assign envelopes = synth.wave_gens[oscillator_index].envelopes;

    oscillator #(
        .WIDTH(`SAMPLE_WIDTH),
        .N_WAVEGENS(`N_OSCILLATORS)
    ) oscillator(
        .clk(sys_clk),
        .enable(synth.wave_gens[oscillator_index].cmds[`WAVEGEN_ENABLE_BIT]),
        .cmds(synth.wave_gens[oscillator_index].cmds),
        .freq(synth.wave_gens[oscillator_index].freq),
        .envelopes(envelopes),
        .amplitude(24'(synth.wave_gens[oscillator_index].velocity)),
        .shape(synth.wave_gens[oscillator_index].shape),
        .index(oscillator_index),
        .out(wave)
    );

    /* Mixer */

    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1:0] mixer_out;
    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1:0] accumulator = 0;
    logic signed [31:0] num_enabled;

    logic [8:0] sample_clk_counter2 = 0;
    always_ff @ (posedge sys_clk) begin
        sample_clk_counter2 <= sample_clk_counter2 + 1;
        if(sample_clk_counter2 < `N_OSCILLATORS) begin
            oscillator_index <= oscillator_index + 1;
            accumulator <= accumulator + wave;
        end

        if(sample_clk_counter2 == `N_OSCILLATORS) begin
            mixer_out <= accumulator;
        end

        if(sample_clk_counter2 >= 383) begin
            sample_clk_counter2 <= 0;
            oscillator_index <= 0;
            //$strobe("Mixer = %d", mixer_out);
            accumulator <= 0;
        end
    end


    /* Reverb */

    // /* Example reverb values for "Large hall" effect */
    // initial synth.reverb.tau = '{
    //     3003, 3403, 3905, 4495, 241, 83
    // };
    // initial synth.reverb.gain = '{
    //     `REAL_TO_FIXED_POINT(0.895),
    //     `REAL_TO_FIXED_POINT(0.883),
    //     `REAL_TO_FIXED_POINT(0.867),
    //     `REAL_TO_FIXED_POINT(0.853),
    //     `REAL_TO_FIXED_POINT(0.7),
    //     `REAL_TO_FIXED_POINT(0.7),
    //     `REAL_TO_FIXED_POINT(0.5)
    // };

    logic signed [31:0] reverb_out;

    reverberator_core u_reverberator_core(
        .clk        (clk        ), // 18 MHz system clock
        .sample_clk (sample_clk ),
        .enable     (1'b1       ),
        .tau        (synth.reverb.tau ),
        .gain       (synth.reverb.gain),
        .in         (mixer_out),
        .out        (reverb_out),
        .debug(debug)
    );


    /* Pan */

    logic signed [`SAMPLE_WIDTH + `FIXED_POINT-1: 0] left;
    logic signed [`SAMPLE_WIDTH + `FIXED_POINT-1: 0] right;

    pan #(.WIDTH(24)) pan(
        .clk(sample_clk),
        .in(reverb_out), //(mixer_out)+fifo_out[0] + fifo_out[1] + fifo_out[2] + fifo_out[3]) >>> 2 ),
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

    /* Count enabled oscillators */
    logic [$clog2(`N_OSCILLATORS):0] num_enabled_count[`N_OSCILLATORS];
    generate;
        genvar i;
        assign num_enabled_count[0] = synth.wave_gens[0].cmds[`WAVEGEN_ENABLE_BIT];
        for (i = 1; i < `N_OSCILLATORS; i++) begin
            assign num_enabled_count[i] = num_enabled_count[i-1] + synth.wave_gens[i].cmds[`WAVEGEN_ENABLE_BIT];
        end
    endgenerate
    always_ff @(posedge sys_clk) begin
        num_enabled <= num_enabled_count[`N_OSCILLATORS-1];
    end

endmodule