`timescale 1ns / 1ps

`include "../rtl_modules/constants.svh"

import shape_pkg::*;
import protocol_pkg::*;

module tb_oscillator;

    logic clk;
    logic enable;
    logic [23:0] amplitude;
    wavegen_t wave_gen;

    logic signed [23:0] out;

    initial amplitude = 200;
    initial enable = 1;
    initial clk = 0;

    always #10 clk = ~clk;

    oscillator #(.WIDTH(24)) oscillator(
        .clk(clk),
        .enable(enable),
        .cmds(wave_gen.cmds), 
        .freq(wave_gen.freq),
        .envelopes(wave_gen.envelopes),
        .amplitude(amplitude),
        .shape(wave_gen.shape),
        .out(out)
    );

    int fd;

    always @ (posedge clk)begin
        $fwrite(fd, "%d\n", `FIXED_POINT_TO_SAMPLE_WIDTH(out));
    end

    initial begin
        wave_gen.freq = `REAL_TO_FIXED_POINT(440);
        wave_gen.velocity = 0;
        wave_gen.shape = SIN;
        wave_gen.cmds = (0 << `ENVELOPE_RESET_BIT) | (1 << `WAVEGEN_ENABLE_BIT);
        
        wave_gen.envelopes[0].gain = `REAL_TO_FIXED_POINT(0);
        wave_gen.envelopes[0].duration = 4800 >> `FIXED_POINT;

        wave_gen.envelopes[1].gain = `REAL_TO_FIXED_POINT(0.99);
        wave_gen.envelopes[1].duration = 4800 >> `FIXED_POINT;

        wave_gen.envelopes[2].gain = `REAL_TO_FIXED_POINT(0.75);
        wave_gen.envelopes[2].duration = 4800 >> `FIXED_POINT;

        wave_gen.envelopes[3].gain = `REAL_TO_FIXED_POINT(0.6);
        wave_gen.envelopes[3].duration = 2400 >> `FIXED_POINT;

        wave_gen.envelopes[4].gain = `REAL_TO_FIXED_POINT(0.3);
        wave_gen.envelopes[4].duration = 4800 >> `FIXED_POINT;

        wave_gen.envelopes[5].gain = `REAL_TO_FIXED_POINT(0.1);
        wave_gen.envelopes[5].duration = 4800 >> `FIXED_POINT;

        wave_gen.envelopes[6].gain = `REAL_TO_FIXED_POINT(0.05);
        wave_gen.envelopes[6].duration = 3 * 9600 >> `FIXED_POINT;

        wave_gen.envelopes[7].gain = `REAL_TO_FIXED_POINT(0);
        wave_gen.envelopes[7].duration = 4800 >> `FIXED_POINT;

        $display("Simulating with the following wavegen");
        print_wavegen_t(wave_gen);

        fd = $fopen("./test_output/oscillator.txt", "w+");

        #1300000;

        $fclose(fd);

        $finish;
    end

endmodule