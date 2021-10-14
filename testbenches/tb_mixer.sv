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
                .enable(1'b1),
                .cmds(synth.wave_gens[i].cmds), 
                .freq(synth.wave_gens[i].freq[15:0]),
                .envelopes(synth.wave_gens[i].envelopes),
                .amplitude(1000),
                .shape(SIN),
                .out(waves[i])
            );
        end
    endgenerate


    mixer #(.WIDTH(24), .N_WAVEGENS(`N_OSCILLATORS)) mixer0 (
        .clk(clk),
        .waves(waves),
        .master_volume(0),
        .num_enabled(num_enabled),
        .out(out)
    );

    int fd;

    always @ (posedge clk)begin
        $fwrite(fd, "%d\n", out);
    end


    initial begin

        reset_synth_t(synth);

        for(int i = 0; i < `N_OSCILLATORS; i++) begin

            synth.wave_gens[i].shape = PIANO;
            synth.wave_gens[i].freq = 0;

            for(int ii = 0; ii < `ENVELOPE_LEN; ii++) begin
                synth.wave_gens[i].envelopes[ii].duration = 10000;
                synth.wave_gens[i].envelopes[ii].gain = 1000 - ii * 125;
            end
        end

        synth.wave_gens[0].freq = 440;
        synth.wave_gens[1].freq = 330;
        synth.wave_gens[2].freq = 277;

        #100;

        fd = $fopen("./test_output/oscillator.txt", "w+");

        #2000000;

        synth.wave_gens[0].cmds = 8'b1;
        synth.wave_gens[1].cmds = 8'b1;
        synth.wave_gens[2].cmds = 8'b1;

        #20;
        
        synth.wave_gens[0].cmds = 8'b0;
        synth.wave_gens[1].cmds = 8'b0;
        synth.wave_gens[2].cmds = 8'b0;

        synth.wave_gens[0].freq = 440;
        synth.wave_gens[1].freq = 330;
        synth.wave_gens[2].freq = 262;

        #2000000;
        $fclose(fd);

        $finish;
    end

endmodule