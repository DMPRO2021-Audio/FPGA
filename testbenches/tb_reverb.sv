`timescale 10ns / 1ns

`include "constants.svh"

import shape_pkg::*;
import protocol_pkg::*;

module tb_reverb;
    logic clk = 0;
    logic sample_clk = 0;
    logic enable;
    logic write = 1;

    localparam WIDTH = 24;

    logic signed [23:0] out;
    logic signed [31:0] mixer_out;
    logic signed [31:0] reverb_in;
    logic signed [31:0] fixed_out;
    logic signed [WIDTH+`FIXED_POINT-1:0] waves [`N_OSCILLATORS];
    logic signed [31:0] num_enabled = 3;

    synth_t synth;

    always #5 clk = ~clk;
    always #1000 sample_clk = ~sample_clk;

    generate;
        genvar i;

        for(i = 0; i < `N_OSCILLATORS; i++) begin
            oscillator #(.WIDTH(WIDTH)) oscillator(
                .clk(sample_clk),
                .enable(synth.wave_gens[i].cmds[`WAVEGEN_ENABLE_BIT]),
                .cmds(synth.wave_gens[i].cmds), 
                .freq(synth.wave_gens[i].freq),
                .envelopes(synth.wave_gens[i].envelopes),
                .amplitude(1000),
                .shape(synth.wave_gens[i].shape),
                .out(waves[i])
            );
        end
    endgenerate


    mixer #(.WIDTH(24), .N_WAVEGENS(`N_OSCILLATORS)) mixer0 (
        .clk(sample_clk),
        .waves(waves),
        .master_volume(synth.master_volume),
        .num_enabled(num_enabled),
        .out(mixer_out)
    );

    assign reverb_in = mixer_out;

    // "Large hall"
    logic signed [0:5][31:0] tau = '{
        3003, 3403, 3905, 4495, 241, 83
    };
    logic signed [0:6][31:0] gain = '{
        `REAL_TO_FIXED_POINT(0.895),
        `REAL_TO_FIXED_POINT(0.883),
        `REAL_TO_FIXED_POINT(0.867),
        `REAL_TO_FIXED_POINT(0.853),
        `REAL_TO_FIXED_POINT(0.7),
        `REAL_TO_FIXED_POINT(0.7),
        `REAL_TO_FIXED_POINT(0.5)
    };

    reverberator_core #(
        .WIDTH     (24     ),
        .MAXDELAY  (`MAX_FILTER_FIFO_LENGTH )
    )
    u_reverberator_core(
    	.clk    (clk    ),
    	.sample_clk(sample_clk),
        .enable (1'b1 ),
        .rstn   (1'b1   ),
        .tau    (tau    ),
        .gain   (gain   ),
        .in     (reverb_in),
        .out    (fixed_out    )
    );

    assign out = `FIXED_POINT_TO_SAMPLE_WIDTH(fixed_out);
    

    int fd;

    always @ (posedge sample_clk)begin
        // $display("Write %d", out);
        $fwrite(fd, "%d\n", out);
    end

    initial begin
        integer i;

        reset_synth_t(synth);
        for (i = 0; i < 6; i++) begin
            $display("[tb_reverb] tau[%01d] = %d",i, tau[i]);
        end
        for (i = 0; i < 7; i++) begin
            $display("[tb_reverb] gain[%01d] = %d",i, gain[i]);
        end

        synth.master_volume = 1024;

        for(int i = 0; i < `N_OSCILLATORS; i++) begin

            synth.wave_gens[i].shape = PIANO;
            synth.wave_gens[i].freq = 0;

            synth.wave_gens[i].envelopes[0].gain = 0;
            synth.wave_gens[i].envelopes[0].duration = 5;

            synth.wave_gens[i].envelopes[1].gain = 8'hff;
            synth.wave_gens[i].envelopes[1].duration = 5;

            synth.wave_gens[i].envelopes[2].gain = 212;
            synth.wave_gens[i].envelopes[2].duration = 10;

            synth.wave_gens[i].envelopes[3].gain = 176;
            synth.wave_gens[i].envelopes[3].duration = 20;

            synth.wave_gens[i].envelopes[4].gain = 8'h80;
            synth.wave_gens[i].envelopes[4].duration = 2 * 20;

            synth.wave_gens[i].envelopes[5].gain = 128;
            synth.wave_gens[i].envelopes[5].duration = 3 * 20;

            synth.wave_gens[i].envelopes[6].gain = 64;
            synth.wave_gens[i].envelopes[6].duration = 3 * 40;

            synth.wave_gens[i].envelopes[7].gain = 0;
            synth.wave_gens[i].envelopes[7].duration = 0;
        end

        for (int i = 0; i < `ENVELOPE_LEN; i++) begin
            $display("[tb_reverb] envelope gain %d = 0x%x", i, synth.wave_gens[0].envelopes[i].gain);
        end

        // Enable to oscillators 0-2
        synth.wave_gens[0].cmds <= 8'b10;
        synth.wave_gens[1].cmds <= 8'b10;
        synth.wave_gens[2].cmds <= 8'b10;

        // Set frequencies of 0-2
        synth.wave_gens[0].freq <= `REAL_TO_FIXED_POINT(440);
        synth.wave_gens[1].freq <= `REAL_TO_FIXED_POINT(329.63);
        synth.wave_gens[2].freq <= `REAL_TO_FIXED_POINT(277.18);

        $strobe("[tb_reverb] Playing %d", synth.wave_gens[0].freq);
        $strobe("[tb_reverb] Playing %d", synth.wave_gens[1].freq);
        $strobe("[tb_reverb] Playing %d", synth.wave_gens[2].freq);

        #4000;

        fd = $fopen("./test_output/oscillator-reverb.txt", "w+");

        #200000000;

        // Disable 0-2
        synth.wave_gens[0].cmds <= 8'b0;
        synth.wave_gens[1].cmds <= 8'b0;
        synth.wave_gens[2].cmds <= 8'b0;
        
        // Enable and reset the envelope of oscillators 3-5
        // Must be enabled to reset
        synth.wave_gens[3].cmds <= 8'b11;
        synth.wave_gens[4].cmds <= 8'b11;
        synth.wave_gens[5].cmds <= 8'b11;

        // #200;

        // // Enable oscillators 3-5
        // synth.wave_gens[3].cmds <= 8'b10;
        // synth.wave_gens[4].cmds <= 8'b10;
        // synth.wave_gens[5].cmds <= 8'b10;        

        // // Set frequencies of 3-5
        // synth.wave_gens[3].freq <= `REAL_TO_FIXED_POINT(440);
        // synth.wave_gens[4].freq <= `REAL_TO_FIXED_POINT(329.63);
        // synth.wave_gens[5].freq <= `REAL_TO_FIXED_POINT(261.63);

        // $strobe("Playing %d", synth.wave_gens[3].freq);
        // $strobe("Playing %d", synth.wave_gens[4].freq);
        // $strobe("Playing %d", synth.wave_gens[5].freq);

        // #10000;

        // // Disable oscillators 3-5
        // synth.wave_gens[3].cmds <= 8'b0;
        // synth.wave_gens[4].cmds <= 8'b0;
        // synth.wave_gens[5].cmds <= 8'b0;

        // // Enable and reset oscillators 6-8
        // synth.wave_gens[6].cmds <= 8'b11;
        // synth.wave_gens[7].cmds <= 8'b11;
        // synth.wave_gens[8].cmds <= 8'b11;

        // #200;
        
        // // Enable oscillators 6-8
        // synth.wave_gens[6].cmds <= 8'b10;
        // synth.wave_gens[7].cmds <= 8'b10;
        // synth.wave_gens[8].cmds <= 8'b10;

        // // Set frequencies of oscillators 6-8
        // synth.wave_gens[6].freq <= `REAL_TO_FIXED_POINT(392);
        // synth.wave_gens[7].freq <= `REAL_TO_FIXED_POINT(329.63);
        // synth.wave_gens[8].freq <= `REAL_TO_FIXED_POINT(261.63);

        // $strobe("Playing %d", synth.wave_gens[6].freq);
        // $strobe("Playing %d", synth.wave_gens[7].freq);
        // $strobe("Playing %d", synth.wave_gens[8].freq);

        // #10000;

        // // Disable 6-8
        // synth.wave_gens[6].cmds <= 8'b0;
        // synth.wave_gens[7].cmds <= 8'b0;
        // synth.wave_gens[8].cmds <= 8'b0;

        // #10000;

        // // Enable and reset 9
        // synth.wave_gens[9].cmds <= 8'b11;

        // #20;
        
        // // Enable 9
        // synth.wave_gens[9].cmds <= 8'b10;

        // // Set frequency of 9
        // synth.wave_gens[9].freq <= `REAL_TO_FIXED_POINT(207.65);
        
        // #150000;

        // // Enable and reset 9
        // synth.wave_gens[9].cmds <= 8'b11;
        // #20;

        // // Enable 9
        // synth.wave_gens[9].cmds <= 8'b10;

        // // Set frequency of 9
        // synth.wave_gens[9].freq <= `REAL_TO_FIXED_POINT(207);

        #300000000;
        $fclose(fd);
        $finish;
    end

endmodule