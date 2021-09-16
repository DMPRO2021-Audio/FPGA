`timescale 1ns / 1ps
// Top level module
// 
// Assign pins and instantiate design

module top(
    input CLK100MHZ,
    input ck_mosi, ck_miso, ck_clk, ck_ss, // SPI
    output [3:0] led
);
    assign led[3:0] = 4'b1010;
    // wire clk = CLK100MHZ;
    // reg [3:0] recv;
    // reg[3:0] led_val = 15;
    // reg[3:0] send = 4'b1010;
    // reg output_valid;

    // assign led = led_val;

    // spi_slave #(.WIDTH(4)) spi0 (
    //     .mosi(ck_mosi),
    //     .miso(ck_miso),
    //     .sclk(ck_clk),
    //     .clk(clk),
    //     .csn(ck_ss),
    //     .recv(recv),
    //     .send(send),
    //     .output_valid(output_valid)
    // );

    // always @(posedge clk) begin
    //     if (output_valid) begin
    //         led_val <= recv;
    //     end
    // end

endmodule