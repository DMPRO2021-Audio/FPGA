`timescale 1ns / 1ps
// module `include "../rtl_modules/top.v"
// `default_nettype none

module tb_top;

bit clk = 0;
logic [3:0] led;

bit mosi;
bit sclk = 0;
bit miso;
bit csel = 1;


top dut
(
    .CLK100MHZ(clk),
    .ck_mosi(mosi), 
    .ck_sck(sclk), 
    .ck_ss(csel),
    .ck_miso(miso), 
    .led(led)
);

localparam CLK_PERIOD = 10;
localparam SCLK_PERIOD = CLK_PERIOD * 5;
always #(CLK_PERIOD/2) clk=~clk;
always #(SCLK_PERIOD/2) sclk=~sclk;

integer i;

initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
end

initial begin
    repeat(6) #(SCLK_PERIOD) $display("leds: %b", led);
end

initial begin
    bit[3:0]msg = 4'b0111; // message
    /* Simulate PISO shift register, serialize and send message */
    for (i = 0; i < 4; i = i + 1) begin
        #(SCLK_PERIOD) csel = 0;
        mosi = msg[i];
    end
    #(SCLK_PERIOD) csel = 1;

    #(SCLK_PERIOD) $finish;
end

endmodule