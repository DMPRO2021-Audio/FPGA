`timescale 1ns / 1ps
// Top level module
//

`include "constants.svh"

import protocol_pkg::*;
import shape_pkg::*;

`define MAX_AMP ((1 << 22) - 1)

// Assign pins and instantiate design
module top(
    input logic CLK48MHZ,

    //input logic ck_mosi, ck_sck, ck_ss,     // SPI
    //output logic ck_miso,                   // SPI

    //input logic [3:0] btn,

    //(* mark_debug="true" *) output logic [3:0] led,

    output logic dac_bit_clk,
    output logic dac_rl_clk,
    output logic dac_sys_clk,
    output logic dac_data,

    output logic [7:0] gpio
);
    /* Declare variables */

    /* Note values C3 to B5 */
    integer n[41];
    initial n = '{
        `REAL_TO_FIXED_POINT(130.813), 
        `REAL_TO_FIXED_POINT(138.591), 
        `REAL_TO_FIXED_POINT(146.832), 
        `REAL_TO_FIXED_POINT(155.563), 
        `REAL_TO_FIXED_POINT(164.814), 
        `REAL_TO_FIXED_POINT(174.614), 
        `REAL_TO_FIXED_POINT(184.997), 
        `REAL_TO_FIXED_POINT(195.998), 
        `REAL_TO_FIXED_POINT(207.652), 
        `REAL_TO_FIXED_POINT(220.000), 
        `REAL_TO_FIXED_POINT(233.082), 
        `REAL_TO_FIXED_POINT(246.942),
        `REAL_TO_FIXED_POINT(261.626), 
        `REAL_TO_FIXED_POINT(277.183), 
        `REAL_TO_FIXED_POINT(293.665), 
        `REAL_TO_FIXED_POINT(311.127), 
        `REAL_TO_FIXED_POINT(329.628), 
        `REAL_TO_FIXED_POINT(349.228), 
        `REAL_TO_FIXED_POINT(369.994), 
        `REAL_TO_FIXED_POINT(391.995), 
        `REAL_TO_FIXED_POINT(415.305), 
        `REAL_TO_FIXED_POINT(440.000), 
        `REAL_TO_FIXED_POINT(466.164), 
        `REAL_TO_FIXED_POINT(493.883),
        `REAL_TO_FIXED_POINT(523.251), 
        `REAL_TO_FIXED_POINT(554.365), 
        `REAL_TO_FIXED_POINT(587.330), 
        `REAL_TO_FIXED_POINT(622.254), 
        `REAL_TO_FIXED_POINT(659.255), 
        `REAL_TO_FIXED_POINT(698.456), 
        `REAL_TO_FIXED_POINT(739.989), 
        `REAL_TO_FIXED_POINT(783.991), 
        `REAL_TO_FIXED_POINT(830.609), 
        `REAL_TO_FIXED_POINT(880.000), 
        `REAL_TO_FIXED_POINT(932.328), 
        `REAL_TO_FIXED_POINT(987.767),
        `REAL_TO_FIXED_POINT(0.00000),
        `REAL_TO_FIXED_POINT(0.00000),
        `REAL_TO_FIXED_POINT(0.00000),
        `REAL_TO_FIXED_POINT(0.00000),
        `REAL_TO_FIXED_POINT(0.00000)
    };


    logic clk;                          // Main internal clock
    logic sample_clk;                   // Clock at the sampling frequency
    
    logic sclk;
    logic dac_bit_clk0;                  // Serial data clock for the dac-transmitter
    logic sys_clk;                      // DAC System clock of the DAC ~18MHz
    logic lrclk0;                        // DAC LR select
    logic sd0;                           // DAC serial data

    assign gpio[0] = sclk;
    assign gpio[1] = sys_clk;
    assign gpio[2] = lrclk0;
    assign gpio[3] = sd0;

    assign dac_bit_clk = sclk;
    assign dac_sys_clk = sys_clk;
    assign dac_rl_clk = rlclk0;
    assign dac_data = sd0;

    //logic rstn;
    //logic[`SPI_WIDTH-1:0] recv;         // Receiving register
    //logic[3:0] led_val = 15;            // Just an initial value: all leds on
    //logic[`SPI_WIDTH-1:0] send;         // Dummy send register (functionality not yet implemented
    //logic ck_sck_reg;
    //logic output_valid;

    assign clk = CLK48MHZ;             // Rename clock

    initial sample_clk <= 0;
    initial dac_bit_clk0 <= 0;

    // Mapping the leds to the upper part of the wave
    // This is only used for debugging and to show that the wave is generated
    // assign led = {
    //     wave >= 7 * (`MAX_AMP >> 3),
    //     wave >= 6 * (`MAX_AMP >> 3),
    //     wave >= 5 * (`MAX_AMP >> 3),
    //     wave >= 4 * (`MAX_AMP >> 3)
    // };
    /* assign led_r[3] = btn[0];
    assign led_r[2] = output_valid;
    assign led_r[1] = ck_sck_reg;
    assign led_b[0] = ~ck_ss | btn[0];  // Turn on when receiving
 */
    logic [31:0] volume;
    logic [31:0] reverb;

/*     // Enable panning by holding btn3 or btn2 and pressing btn1
    logic signed [31:0] lr_weight = `REAL_TO_FIXED_POINT(0);
    always_ff @(posedge btn[1]) begin
        if(btn[3] && lr_weight > `REAL_TO_FIXED_POINT(-1.0)) begin
            lr_weight <= lr_weight + `REAL_TO_FIXED_POINT(-0.1);
        end else if(btn[2] && lr_weight < `REAL_TO_FIXED_POINT(1.0)) begin
            lr_weight <= lr_weight + `REAL_TO_FIXED_POINT(0.1);
        end
    end */
    

    wavegen_t wave_gens[2];
    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1:0] wave;
    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1:0] waves [2];

    // Sending to oscillator
    wavegen_t wave_gen;
    initial begin
        integer i;

        for(i = 0; i < 2; i++) begin
            wave_gens[i].velocity = 500000;
            wave_gens[i].shape = PIANO;
            wave_gens[i].cmds = 0 << `ENVELOPE_RESET_BIT | 1 << `WAVEGEN_ENABLE_BIT;

            wave_gens[i].envelopes[0].gain = `REAL_TO_FIXED_POINT(0);
            wave_gens[i].envelopes[0].duration = 1200;

            wave_gens[i].envelopes[1].gain = `REAL_TO_FIXED_POINT(2);
            wave_gens[i].envelopes[1].duration = 1200;

            wave_gens[i].envelopes[2].gain = `REAL_TO_FIXED_POINT(1.5);
            wave_gens[i].envelopes[2].duration = 1200;

            wave_gens[i].envelopes[3].gain = `REAL_TO_FIXED_POINT(1);
            wave_gens[i].envelopes[3].duration = 2400;

            wave_gens[i].envelopes[4].gain = `REAL_TO_FIXED_POINT(1);
            wave_gens[i].envelopes[4].duration = 4800;

            wave_gens[i].envelopes[5].gain = `REAL_TO_FIXED_POINT(0.5);
            wave_gens[i].envelopes[5].duration = 4800;

            wave_gens[i].envelopes[6].gain = `REAL_TO_FIXED_POINT(0.25);
            wave_gens[i].envelopes[6].duration = 3 * 9600;

            wave_gens[i].envelopes[7].gain = `REAL_TO_FIXED_POINT(1);
            wave_gens[i].envelopes[7].duration = 4800;
        end
    
    end

    /* Sample tunes */
    integer tbt_normalen_pitch[54] = '{16, 17, 19, 19, 21, 16, 12, 12, 9, 9, 12, 12, 14, 15, 14, 12, 19, 19, 19, 21, 22, 21, 22, 21, 19, 36, 16, 17, 19, 19, 19, 21, 16, 12, 12, 9, 9, 12, 12, 14, 15, 14, 12, 12, 17, 17, 17, 19, 16, 12, 12, 9, 12, 36};
    // length in 8ths
    integer tbt_normalen_len[54]   = '{1,  1,  2,  1,  1,  1,  1,  1, 1, 1,  1,  1,  1,  1,  1,  2,  1,  1,  1,  1,  1,  1,  1,  1,  2,  4,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, 1, 1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, 4,  4 };
    integer tbt_normalen_tempo = 116 * 2; // 116 bpm to 8ths
    initial wave_gen.freq = tbt_normalen_pitch[0];

    integer counter = 0;
    integer idx = 0;
    integer tones[4] = '{12, 16, 19, 16};
    always @(posedge sample_clk) begin
        if (counter >= (`SAMPLE_RATE * 60 / tbt_normalen_tempo) * tbt_normalen_len[idx]) begin
            counter <= 0;
            idx <= (idx + 1) % 54;
            wave_gens[0].cmds <= wave_gen.cmds | 1 << `ENVELOPE_RESET_BIT;
            wave_gens[1].cmds <= wave_gen.cmds | 1 << `ENVELOPE_RESET_BIT;
        end
        else begin
            wave_gens[0].cmds <= wave_gen.cmds & ~(1 << `ENVELOPE_RESET_BIT);
            wave_gens[1].cmds <= wave_gen.cmds & ~(1 << `ENVELOPE_RESET_BIT);
            wave_gens[0].freq <= n[tbt_normalen_pitch[idx]];
            wave_gens[1].freq <= n[tbt_normalen_pitch[idx] + 4];
            counter <= counter + 1;
        end
    end
    //assign led[3:0] = idx[3:0];
    /* End sample tunes */

    logic locked;

    // Placeholders for unused signals
    logic in_placeholder = 1;
    logic out_placeholder;

    /* Instantiate modules */

`ifndef DEBUG
    /* Create correct clock on dev board */
    clk_wiz clk_wiz (
        .clk_in(clk),
        .reset(0),
        .clk_out(sys_clk),
        .locked(locked)
    );
`else
    assign sys_clk = clk;
    assign locked = 1;
`endif

    // spi_slave #(.WIDTH(`SPI_WIDTH)) spi0 (
    //     .mosi(ck_mosi),
    //     .miso(ck_miso),
    //     .sclk(ck_sck),
    //     .clk(clk),
    //     .csn(ck_ss),
    //     .recv(recv),
    //     .send(send),
    //     .output_valid(output_valid)
    // );

/*     control_unit cu0 (
        .sig_in(recv),
        .clk(clk),
        .enable(output_valid),
        .rstn(in_placeholder),
        .volume(volume),
        .reverb(reverb),
        .wave_gens(wave_gens)
    ); */

    generate;
        genvar i;

        for(i = 0; i < 2; i++) begin
            oscillator #(.WIDTH(`SAMPLE_WIDTH)) oscillator(
                .clk(sample_clk),
                .enable(1),
                .cmds(wave_gens[i].cmds), 
                .freq(wave_gens[i].freq),
                .envelopes(wave_gens[i].envelopes),
                .amplitude(24'(wave_gens[i].velocity)),
                .shape(wave_gens[i].shape),
                .out(waves[i])
            );
        end

    endgenerate  

    mixer #(.WIDTH(`SAMPLE_WIDTH), .N_WAVEGENS(2)) mixer(
        .clk(sample_clk),
        .waves(waves),
        .master_volume(`REAL_TO_FIXED_POINT(1)),
        .num_enabled(2),
        
        .out(wave)
    );

    logic signed [`SAMPLE_WIDTH + `FIXED_POINT-1: 0] left;
    logic signed [`SAMPLE_WIDTH + `FIXED_POINT-1: 0] right;

    pan #(.WIDTH(24)) pan(
        .clk(sample_clk),
        .in(wave),
        .lr_weight(lr_weight),
        .left(left),
        .right(right)
    );

    dac_transmitter #(.WIDTH(`SAMPLE_WIDTH)) transmitter0(
        .clk(dac_bit_clk0),
        .enable(locked),
        .left_data(`FIXED_POINT_TO_SAMPLE_WIDTH(left)),
        .right_data(`FIXED_POINT_TO_SAMPLE_WIDTH(right)),

        .sclk(sclk),   // Serial data clock
        .lrclk(rlclk0),  // Left right channel select
        .sd(sd0)
    );

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
            dac_bit_clk0 <= ~dac_bit_clk0;
        end
    end

endmodule