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
        .freq(wave_gen.freq[15:0]),
        .envelopes(wave_gen.envelopes),
        .amplitude(amplitude),
        .shape(wave_gen.shape),
        .out(out)
    );

    int fd;

    always @ (posedge clk)begin
        $fwrite(fd, "%d\n", out);
    end

    initial begin
        wave_gen.freq = 440;
        wave_gen.velocity = 0;
        wave_gen.shape = PIANO;
        wave_gen.cmds = 0 << `ENVELOPE_RESET_BIT;
        
        wave_gen.envelopes[0].gain = 100;
        wave_gen.envelopes[0].duration = 4800;

        wave_gen.envelopes[1].gain = 200;
        wave_gen.envelopes[1].duration = 4800;

        wave_gen.envelopes[2].gain = 300;
        wave_gen.envelopes[2].duration = 4800;

        wave_gen.envelopes[3].gain = 300;
        wave_gen.envelopes[3].duration = 2400;

        wave_gen.envelopes[4].gain = 300;
        wave_gen.envelopes[4].duration = 4800;

        wave_gen.envelopes[5].gain = 100;
        wave_gen.envelopes[5].duration = 4800;

        wave_gen.envelopes[6].gain = 100;
        wave_gen.envelopes[6].duration = 3 * 9600;

        wave_gen.envelopes[7].gain = 0;
        wave_gen.envelopes[7].duration = 4800;

        $display("Simulating with the following wavegen");
        print_wavegen_t(wave_gen);

        fd = $fopen("./test_output/oscillator.txt", "w+");

        #600000;

        $fclose(fd);

        $finish;
    end

endmodule