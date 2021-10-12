`timescale 1ns / 1ps

/*
    Based on the following design:
    https://www.hackster.io/Kampino/playing-audio-with-an-fpga-d2bc85
*/

module I2S_Transmitter
#(
    parameter WIDTH = 24
)
(
    input clk,                      // Clock of the transmitter, required frequency: 2 * WIDTH * 44.1Khz
    input enable,
    input [WIDTH-1:0] left_data,    // Date from the left channel
    input [WIDTH-1:0] right_data,   // Data from the right channel

    output sclk,    // Serial clock
    output lrclk,   // Left / right world select (high = left)
    output sd       // Serial data
);

    reg [$clog2(WIDTH) + 1:0] bit_counter;
    reg [2:0] state;
    reg [WIDTH-1:0] left_shift_reg;
    reg [WIDTH-1:0] right_shift_reg;
    reg lrclk_reg; 

    initial bit_counter = 0;
    initial lrclk_reg = 1;

    assign lrclk = lrclk_reg;
    assign sd = (lrclk_reg ? left_shift_reg[WIDTH-1] : right_shift_reg[WIDTH-1]);
    assign sclk = clk;

    always @(negedge(clk)) begin
        if(enable) begin

            bit_counter <= bit_counter + 1;

            if(bit_counter < WIDTH) begin
                left_shift_reg <= left_shift_reg << 1;
            end else begin
                right_shift_reg <= right_shift_reg << 1;
            end

            if(bit_counter == WIDTH - 1)begin
                lrclk_reg <= 0;
            end

            if(bit_counter == (2 * WIDTH) - 1) begin
                lrclk_reg <= 1;
                left_shift_reg <= left_data;
                right_shift_reg <= right_data;
                bit_counter <= 0;
            end
            
        end else begin
            bit_counter <= 0;
            lrclk_reg <= 1;
            left_shift_reg <= left_data;
            right_shift_reg <= right_data;
        end
    end
endmodule
