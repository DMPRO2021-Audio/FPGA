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
    output [3:0] ja                     // Output to DAC
);
    // assign led[3:0] = 4'b1010;
    logic clk;          
    logic sys_clk;                      // System clock of the DAC
    logic sample_clk;                   // Clock at the sampling frequency
    logic dac_bit_clk;                  // Serial data clock for the dac-transmitter
    
    logic rstn;
    logic[`SPI_WIDTH-1:0] recv;         // Receiving register
    logic[3:0] led_val = 15;            // Just an initial value: all leds on
    logic[`SPI_WIDTH-1:0] send;         // Dummy send register (functionality not yet implemented
    logic ck_sck_reg;
    logic output_valid;
    
    assign clk = CLK100MHZ;   // Rename clock
    
    initial sample_clk = 0;
    initial dac_bit_clk = 0;

    // Mapping the leds to the upper part of the wave
    // This is only used for debugging and to show that the wave is generated
    logic wave;
    `define MAX_AMP ((1 << 23) - 1)
    assign led = {
        wave >= 7 * (`MAX_AMP >> 3),
        wave >= 6 * (`MAX_AMP >> 3),
        wave >= 5 * (`MAX_AMP >> 3),
        wave >= 4 * (`MAX_AMP >> 3),
    };
    assign led_r[3] = 1;
    assign led_r[2] = output_valid;
    assign led_r[1] = ck_sck_reg;
    assign led_b[0] = ~ck_ss | btn[0]; // Turn on when receiving


    clk_wiz_dev clk_wiz (
        .clk_in(clk),
        .reset(0),
        .clk_out(sys_clk),
        .locked(locked)
    );

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

    oscillator #(.WIDTH(24)) oscillator0(
        .clk(sample_clk),
        .enable(locked),
        .freq(1),                   
        .amplitude(`MAX_AMP),
        .shape(SIN),

        .out(wave)
    );

    dac_transmitter #(.WIDTH(24)) transmitter0(
        .clk(dac_bit_clk),
        .enable(locked),
        .left_data(wave),
        .right_data(wave),

        .sclk(sclk),
        .lrclk(lrclk),
        .sd(sd)
    );
    
    logic [31:0] volume;
    logic [31:0] reverb;
    wavegen_t wave_gens[`N_OSCILLATORS];

    logic in_placeholder = 1;
    logic out_placeholder;

    /* 
        Deriving the sample clock (48 KHz) and 
        the dac-transmitter serial data clock (2 * 24 * 48Khz)
        from the DAC system clock (384 * 48KHz)
    */

    logic [7:0] sample_clk_counter = 0;
    logic [2:0] dac_bit_clk_counter = 0;

    always_ff @(posedge sys_clk) begin
        sample_clk_counter <= sample_clk_counter + 1;
        dac_bit_clk_counter <= dac_bit_clk_counter + 1;
        
        // Dividing the clock frequency by 384
        if(sample_clk_counter >= 192) begin
            sample_clk_counter <= 0;
            sample_clk <= ~sample_clk; 
        end

        // Dividing the clock frequency by 8
        if(dac_bit_clk_counter >= 4) begin
            dac_bit_clk_counter <= 0;
            dac_bit_clk <= ~dac_bit_clk;
        end
    end

endmodule