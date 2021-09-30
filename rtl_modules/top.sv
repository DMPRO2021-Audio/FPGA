`timescale 1ns / 1ps
// Top level module
// 

// Defines
`define SPI_WIDTH 8

// Assign pins and instantiate design
module top(
    input CLK100MHZ,

    input ck_mosi, ck_sck, ck_ss,   // SPI
    output ck_miso,                 // SPI

    input [3:0] btn,

    (* mark_debug="true" *) output [3:0] led,
    output [3:0] led_r, led_g, led_b
);
    // assign led[3:0] = 4'b1010;
    wire clk = CLK100MHZ;   // Rename clock
    wire [`SPI_WIDTH-1:0] recv;         // Receiving register
    reg[3:0] led_val = 15;  // Just an initial value: all leds on
    reg[`SPI_WIDTH-1:0] send;// Dummy send register (functionality not yet implemented
    reg ck_sck_reg;
    wire output_valid;

    assign led = led_val;
    assign led_r[3] = 1;
    assign led_r[2] = output_valid;
    assign led_r[1] = ck_sck_reg;
    assign led_b[0] = ~ck_ss | btn[0]; // Turn on when receiving

    spi_slave #(.WIDTH(`SPI_WIDTH)) spi0 (
        .mosi(ck_mosi),
        .miso(ck_miso),
        .sclk(ck_sck),
        .clk(clk),
        .csn(ck_ss),
        .recv(recv),
        .send(send),
        .output_valid(output_valid)
    );

    // Assign led values
    always @(posedge clk) begin
        if (output_valid) begin
            led_val <= recv[3:0];
        end
    end

endmodule