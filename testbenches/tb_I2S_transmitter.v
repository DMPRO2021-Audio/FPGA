`timescale 1ns / 1ps
module tb_I2S_transmitter;

    reg clk;
    reg nReset;
    reg [23:0] left_data_in;
    reg [23:0] right_data_in;

    wire sclk;
    wire lrclk;
    wire sd;

    reg [23:0] out_reg;

    initial out_reg = 0;
    initial clk = 0;
    initial nReset = 1;
    initial left_data_in = 24'hffffff;
    initial right_data_in = 24'h000000;

    always #10 clk = ~clk;

    I2S_Transmitter #(.WIDTH(24)) transmitter(
        .clk(clk),
        .enable(1'b1),
        .left_data(left_data_in),
        .right_data(right_data_in),
        .sclk(sclk),
        .lrclk(lrclk),
        .sd(sd)
    );

    always @ (posedge lrclk) begin
        $display("Right = %h", out_reg);
    end

    always @ (negedge lrclk) begin
        $display("Left = %h", out_reg);
    end
    
    always @ (posedge sclk) begin
        out_reg = (out_reg << 1) | sd;
    end

    initial begin
        #960;

        left_data_in <= 24'h010101;
        right_data_in <= 24'h101010;

        #2010;
        $finish;
    end

endmodule