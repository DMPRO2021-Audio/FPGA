`timescale 1ns / 1ps

`include "../rtl_modules/constants.svh"

import shape_pkg::*;
import protocol_pkg::*;

module tb_mixer;

    logic clk = 0;
    logic enable;

    localparam WIDTH = 24;

    logic signed [23:0] out;
    logic signed [WIDTH-1:0] waves [`N_OSCILLATORS];
    logic signed [31:0] num_enabled = 3;

    synth_t synth;

    always #10 clk = ~clk;

    generate;
        genvar i;

        for(i = 0; i < `N_OSCILLATORS; i++) begin
            oscillator #(.WIDTH(WIDTH)) oscillator(
                .clk(clk),
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
        .clk(clk),
        .waves(waves),
        .master_volume(synth.volume),
        .num_enabled(num_enabled),
        .out(out)
    );

    int fd;

    always @ (posedge clk)begin
        $fwrite(fd, "%d\n", out);
    end

    initial begin

        reset_synth_t(synth);

        synth.volume = 1024;

        for(int i = 0; i < `N_OSCILLATORS; i++) begin

            synth.wave_gens[i].shape = SAWTOOTH;
            synth.wave_gens[i].freq = 0;

            synth.wave_gens[i].envelopes[0].duration = 3000;
            synth.wave_gens[i].envelopes[0].gain = 0;
            
            synth.wave_gens[i].envelopes[1].duration = 3000;
            synth.wave_gens[i].envelopes[1].gain = 125;

            synth.wave_gens[i].envelopes[2].duration = 1000;
            synth.wave_gens[i].envelopes[2].gain = 75;

            for(int ii = 3; ii < `ENVELOPE_LEN; ii++) begin
                synth.wave_gens[i].envelopes[ii].duration = 15000;
                synth.wave_gens[i].envelopes[ii].gain = 75;
            end
        
            synth.wave_gens[i].envelopes[7].gain = 0;
        end

        // Enable to oscillators 0-2
        synth.wave_gens[0].cmds <= 8'b10;
        synth.wave_gens[1].cmds <= 8'b10;
        synth.wave_gens[2].cmds <= 8'b10;

        // Set frequencies of 0-2
        synth.wave_gens[0].freq <= `REAL_TO_FREQ_FIXED_POINT(440);
        synth.wave_gens[1].freq <= `REAL_TO_FREQ_FIXED_POINT(329.63);
        synth.wave_gens[2].freq <= `REAL_TO_FREQ_FIXED_POINT(277.18);

        $strobe("Playing %d", synth.wave_gens[0].freq);
        $strobe("Playing %d", synth.wave_gens[1].freq);
        $strobe("Playing %d", synth.wave_gens[2].freq);

        #100;

        fd = $fopen("./test_output/oscillator.txt", "w+");

        #1500000;

        // Disable 0-2
        synth.wave_gens[0].cmds <= 8'b0;
        synth.wave_gens[1].cmds <= 8'b0;
        synth.wave_gens[2].cmds <= 8'b0;
        
        // Enable and reset the envelope of oscillators 3-5
        // Must be enabled to reset
        synth.wave_gens[3].cmds <= 8'b11;
        synth.wave_gens[4].cmds <= 8'b11;
        synth.wave_gens[5].cmds <= 8'b11;

        #20;

        // Enable oscillators 3-5
        synth.wave_gens[3].cmds <= 8'b10;
        synth.wave_gens[4].cmds <= 8'b10;
        synth.wave_gens[5].cmds <= 8'b10;        

        // Set frequencies of 3-5
        synth.wave_gens[3].freq <= `REAL_TO_FREQ_FIXED_POINT(440);
        synth.wave_gens[4].freq <= `REAL_TO_FREQ_FIXED_POINT(329.63);
        synth.wave_gens[5].freq <= `REAL_TO_FREQ_FIXED_POINT(261.63);

        $strobe("Playing %d", synth.wave_gens[3].freq);
        $strobe("Playing %d", synth.wave_gens[4].freq);
        $strobe("Playing %d", synth.wave_gens[5].freq);

        #1500000;

        // Disable oscillators 3-5
        synth.wave_gens[3].cmds <= 8'b0;
        synth.wave_gens[4].cmds <= 8'b0;
        synth.wave_gens[5].cmds <= 8'b0;

        // Enable and reset oscillators 6-8
        synth.wave_gens[6].cmds <= 8'b11;
        synth.wave_gens[7].cmds <= 8'b11;
        synth.wave_gens[8].cmds <= 8'b11;

        #20;
        
        // Enable oscillators 6-8
        synth.wave_gens[6].cmds <= 8'b10;
        synth.wave_gens[7].cmds <= 8'b10;
        synth.wave_gens[8].cmds <= 8'b10;

        // Set frequencies of oscillators 6-8
        synth.wave_gens[6].freq <= `REAL_TO_FREQ_FIXED_POINT(392);
        synth.wave_gens[7].freq <= `REAL_TO_FREQ_FIXED_POINT(329.63);
        synth.wave_gens[8].freq <= `REAL_TO_FREQ_FIXED_POINT(261.63);

        $strobe("Playing %d", synth.wave_gens[6].freq);
        $strobe("Playing %d", synth.wave_gens[7].freq);
        $strobe("Playing %d", synth.wave_gens[8].freq);

        #1500000;

        // Disable 6-8
        synth.wave_gens[6].cmds <= 8'b0;
        synth.wave_gens[7].cmds <= 8'b0;
        synth.wave_gens[8].cmds <= 8'b0;

        // Enable and reset 9
        synth.wave_gens[9].cmds <= 8'b11;

        #20;
        
        // Enable 9
        synth.wave_gens[9].cmds <= 8'b10;

        // Set frequency of 9
        synth.wave_gens[9].freq <= `REAL_TO_FREQ_FIXED_POINT(207.65);
        
        #1500000;

        // Enable and reset 9
        synth.wave_gens[9].cmds <= 8'b11;
        #20;

        // Enable 9
        synth.wave_gens[9].cmds <= 8'b10;

        // Set frequency of 9
        synth.wave_gens[9].freq <= `REAL_TO_FREQ_FIXED_POINT(207);

        #1500000;
        $fclose(fd);
        $finish;
    end

endmodule