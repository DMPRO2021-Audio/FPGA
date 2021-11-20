`timescale 1ns / 1ps
`define DEBUG
module tb_fifovd;
    logic clk = 0;
    logic sample_clk = 0;
    always #1 clk = ~clk;
    always #10 sample_clk = ~sample_clk;
    logic resetn = 1;
    logic enable = 1;

    logic [11:0] in_value = 0;
    logic [11:0] out_value;
    logic write = 0;
    logic [31:0] len = 20;
    fifo_delay_bram #(.WIDTH(12), .MAXLEN(30)) fifo_0(
        .clk(clk), 
        .sample_clk(sample_clk), 
        //.rstn(resetn),
        .enable(enable),
        .in(in_value), 
        .len(len),
        //.write(write),
        .out(out_value)
        );

    initial begin
        #0 in_value = 12'h 1;
        $display("out = %d at time %t", out_value, $time);
        #20 in_value = 12'h 2;
        $display("out = %d at time %t", out_value, $time);
        #20 in_value = 12'h 3;
        $display("out = %d at time %t", out_value, $time);
        #20 in_value = 12'h 4;
        $display("out = %d at time %t", out_value, $time);
        #20 in_value = 12'h 5;
        $display("out = %d at time %t", out_value, $time);
        #20 in_value = 12'h 0;
        $display("out = %d at time %t", out_value, $time);
        for (int i = 0; i < 30; i++) begin
            #20 $display("out = %d at time %t", out_value, $time);
        end
        #300 $finish;
    end

endmodule