`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: NTNU TDT4295 Computer Project FALL21
// Engineer: 
// 
// Create Date: 09.09.2021 13:11:27
// Design Name: 
// Module Name: I2S - transmitter
// Project Name: Audio project - Synth
// Target Devices: 
// Tool Versions: 
// Description: I2S module for sending two data streams, left and right.
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

/*
    Based on the following design:
    https://www.hackster.io/Kampino/playing-audio-with-an-fpga-d2bc85
*/

module I2S_Transmitter
#(
    parameter WORD_SIZE = 24
)
(
    input clk,                          // Clock of the transmitter, required frequency: 2 * WORD_SIZE * 44.1Khz
    input nReset,                       // Active low reset signal
    input [WORD_SIZE-1:0] left_data,    // Date from the left channel
    input [WORD_SIZE-1:0] right_data,   // Data from the right channel

    output sclk,    // Serial clock
    output lrclk,   // Left / right world select (high = left)
    output sd       // Serial data
);

    localparam STATE_RESET    = 0;
    localparam STATE_LOAD     = 1;
    localparam STATE_TRANSMIT = 2;

    reg [$clog2(WORD_SIZE) + 1:0] bit_counter;
    reg [2:0] state;
    reg [WORD_SIZE:0] left_shift_reg;
    reg [WORD_SIZE:0] right_shift_reg;
    reg lrclk_reg; 

    initial state = STATE_LOAD;
    initial bit_counter = 0;
    initial lrclk_reg = 0;

    assign lrclk = lrclk_reg;
    assign sd = (lrclk_reg ? right_shift_reg[WORD_SIZE-1] : left_shift_reg[WORD_SIZE-1]);
    assign sclk = clk;

    always @(negedge(clk)) begin
        case(state)
        STATE_RESET: begin
            lrclk_reg <= 0;
            left_shift_reg <= 0;
            right_shift_reg <= 0;
            state = STATE_LOAD;
        end
        STATE_LOAD: begin
            bit_counter <= 0;
            lrclk_reg <= 0;
            left_shift_reg <= left_data;
            right_shift_reg <= right_data;
            state = STATE_TRANSMIT;
        end
        STATE_TRANSMIT: begin
            bit_counter <= bit_counter + 1;

            if(bit_counter == WORD_SIZE - 1)begin
                lrclk_reg <= 1;
            end
            
            if(bit_counter >= WORD_SIZE) begin
                right_shift_reg <= right_shift_reg << 1;
            end
            else begin
                left_shift_reg <= left_shift_reg << 1;
            end

            if(bit_counter >= (2 * WORD_SIZE) - 1) begin
                lrclk_reg <= 0;
                state <= STATE_LOAD;
            end
        end
        endcase

        if(nReset == 0) begin
            state <= STATE_RESET;
        end 
    end
endmodule
