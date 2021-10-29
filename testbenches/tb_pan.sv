`timescale 1ns / 1ps

`include "constants.svh"

module tb_pan;
    logic clk = 0;
    
    always #5 clk = ~clk;

    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1: 0] left;
    logic signed [`SAMPLE_WIDTH + `FIXED_POINT - 1: 0] right;

    logic signed [31:0] lr_weight = `REAL_TO_FIXED_POINT(0);

    pan #(.WIDTH(`SAMPLE_WIDTH)) pan0(
        .clk(clk), 
        .in(32'h7fffffff),
        .lr_weight(lr_weight), 
        .left(left),
        .right(right)
    );

    initial begin
        lr_weight <= `REAL_TO_FIXED_POINT(0);
        $strobe("==============================================\nWeight = %d", lr_weight);
        #30;
        $strobe("LEFT = %d, RIGHT = %d", left, right);
        lr_weight <= `REAL_TO_FIXED_POINT(1);
        $strobe("==============================================\nWeight = %d", lr_weight);
        #30;
        $strobe("LEFT = %d, RIGHT = %d", left, right);
        lr_weight <= `REAL_TO_FIXED_POINT(-1);
        $strobe("==============================================\nWeight = %d", lr_weight);
        #30;
        $strobe("LEFT = %d, RIGHT = %d", left, right);
        #5;
        $finish;
    end

endmodule