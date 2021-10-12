`timescale 1ns / 1ps

`include "../rtl_modules/constants.svh"

import shape_pkg::*;
import protocol_pkg::*;

module tb_oscillator;

    logic clk;
    logic enable;
    logic [23:0] amplitude;
    wave_shape shape;
    wavegen_t wave_gen;

    logic [23:0] out;

    initial amplitude = 200;
    initial shape = SIN;
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
        .shape(shape),
        .out(out)
    );

    int fd;

    always @ (posedge clk)begin
        $fwrite(fd, "%d\n", out);
    end

    initial begin
        wave_gen.freq = 400;
        wave_gen.velocity = 0;
        wave_gen.shape = SIN;
        wave_gen.cmds = 0 << `ENVELOPE_RESET_BIT;
        
        wave_gen.envelopes[0].rate = 100;
        wave_gen.envelopes[0].duration = 48000;

        wave_gen.envelopes[1].rate = 200;
        wave_gen.envelopes[1].duration = 48000;

        wave_gen.envelopes[2].rate = 200;
        wave_gen.envelopes[2].duration = 48000;

        wave_gen.envelopes[3].rate = 300;
        wave_gen.envelopes[3].duration = 24000;

        wave_gen.envelopes[4].rate = 250;
        wave_gen.envelopes[4].duration = 48000;

        wave_gen.envelopes[5].rate = 100;
        wave_gen.envelopes[5].duration = 48000;

        wave_gen.envelopes[6].rate = 500;
        wave_gen.envelopes[6].duration = 3 * 96000;

        wave_gen.envelopes[7].rate = 400;
        wave_gen.envelopes[7].duration = 48000;

        $display("Simmulating with the following wavegen");
        print_wavegen_t(wave_gen);

        fd = $fopen("./test_output/oscillator.txt", "w+");

        #20000000;

        $fclose(fd);

        $finish;
    end

endmodule