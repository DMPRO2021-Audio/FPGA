`timescale 1ns / 1ps

import shape_pkg::*;

module tb_oscillator;

    reg clk;
    reg enable;
    reg [15:0] freq;
    reg [23:0] amplitude;
    wave_shape shape;

    wire [23:0] out;

    initial amplitude = 4000;
    initial freq = 400;
    initial shape = SIN;
    initial enable = 1;
    initial clk = 0;

    always #10 clk = ~clk;

    oscillator #(.WIDTH(24)) oscillator(
        .clk(clk),
        .enable(enable),
        .freq(freq),
        .amplitude(amplitude),
        .shape(shape),
        .out(out)
    );

    initial begin
        #10000;

        freq <= 880;

        #10000;

        amplitude <= 1000;

        #10000;

        shape <= SQUARE;

        #10000;

        shape <= SAWTOOTH;

        #10000;
        $finish;
    end

endmodule