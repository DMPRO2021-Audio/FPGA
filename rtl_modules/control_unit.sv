`timescale 1ns / 1ps

`include constants.svh

import protocol_pkg::*;
import shape_pkg::*;

//-------------------------------------------------------------------------------------------------/
// Control unit for FPGA, handles commands from MCU, stores configuration values and controls
// effect modules.
// 
// ## When enable signal is activated
// Clock in config struct, WIDTH bits at the time
//
// Might add some on-demand feedback to mcu later?
//-------------------------------------------------------------------------------------------------/

module reciever_control_unit #(
    parameter WIDTH = 8,        // Width of message words coming from receiver (SPI slave)
    parameter WORD = 32,        // Word size
) (
    input [WIDTH-1:0] sig_in,   // Signal in
    input clk, enable, rstn,    // Control signals

    output output_valid,        // Signal full message has been recieved
    /* Global values of synth_t */
    output logic    [WORD-1:0]       volume,
    output logic    [WORD-1:0]       reverb,
    /* Array of oscillators */
    output wavegen_t wave_gens[`N_OSCILLATORS]
);

    synth_t conf;
    logic[WIDTH-1:0] buffer [$bits(synth_t)/WIDTH];

    integer counter = 0;

    always_ff @ (posedge(clk)) begin
        if (!rstn) begin
            wave_gens <= '{default:0}; 
            conf <= '{default:0};
            buffer <= '{default:0};
        end
        else if (enable) begin
            if (counter < $size(buffer)) begin
            buffer[counter] <= sig_in;
            counter <= counter + 1
`ifdef DEBUG
            $display("Address map of synth_t");
            for (int i = 0; i < $size(buffer)/4; i++) begin
                case ($size(buffer) - i)
                    1:  $display("%x: %x", i*4, buffer[i]);
                    2:  $display("%x: %x %x", i*4, buffer[i], buffer[i+1]);
                    3:  $display("%x: %x %x %x", i*4, buffer[i], buffer[i+1], buffer[i+2]);
                    default: begin
                        $display("%x: %x %x %x %x", i*4, buffer[i], buffer[i+1], buffer[i+2], buffer[i+3]);
                    end
                endcase
            end
`endif
        end
    end
endmodule