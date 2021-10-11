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
    initial shape = SAWTOOTH;
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

    int fd;

    always @ (posedge clk)begin
        $fwrite(fd, "%d\n", out);
        amplitude <= amplitude + 100;
    end

    initial begin
        
        fd = $fopen("./test_output/oscillator.txt", "w+");

        #10000;
       shape <= SIN;
        #10000;
       freq <= 880;
        #10000;

        $fclose(fd);

        $finish;
    end

endmodule