`timescale 1ns / 1ps
// Top level module
// 

`include "constants.svh"

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
    logic clk;
    logic rstn;
    logic[`SPI_WIDTH-1:0] recv;         // Receiving register
    logic[3:0] led_val = 15;  // Just an initial value: all leds on
    logic[`SPI_WIDTH-1:0] send;// Dummy send register (functionality not yet implemented
    logic ck_sck_reg;
    logic output_valid;
    
    assign clk = CLK100MHZ;   // Rename clock

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

    
    logic [31:0] volume;
    logic [31:0] reverb;
    wavegen_t wave_gens[`N_OSCILLATORS];

    logic in_placeholder = 1;
    logic out_placeholder;

    receiver_control_unit cu0 (
        .sig_in(recv),
        .clk(clk),
        .enable(output_valid),
        .rstn(in_placeholder),
        .volume(volume),
        .reverb(reverb),
        .wave_gens(wave_gens)
    );

    // Assign led values
    always_ff @(posedge clk) begin
        if (output_valid) begin
            led_val <= recv[3:0];
`ifdef DEBUG
            $display("[top] output_valid=1, recv=%x", recv);
`endif
        end
    end

endmodule