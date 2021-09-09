`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.09.2021 13:11:27
// Design Name: 
// Module Name: DigitalOscillator
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module DigitalOscillator(
    input CLK100MHZ,
    input enable,       // Generate audio signal, else output is 0
    input [10:0] freq,  // Frequency of the oscillator
    output [12:0] out   // 12 bit audio sample
);

    reg[12:0] phase = 0;
    
    // For now this outputs a sawtooth wave
    
    always @ (posedge(CLK100MHZ)) begin
        if(enable) begin
            phase <= phase + 2^12 * freq / 100000000;
            out <= phase;
        end
        else begin
            out <= 0;
        end
    end


endmodule
