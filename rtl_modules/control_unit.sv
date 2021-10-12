`timescale 1ns / 1ps

`include "constants.svh"

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

module receiver_control_unit #(
parameter WIDTH = 8,                // Width of message words coming from receiver (SPI slave)
parameter WORD = 32                 // Word size
) (
    input logic [WIDTH-1:0] sig_in, // Signal in
    /* Control signals */
    input logic clk,
    input logic enable, 
    input logic rstn,  

    output output_valid,            // Signal full message has been recieved
    /* Global values of synth_t */
    output logic    [WORD-1:0]       volume,
    output logic    [WORD-1:0]       reverb,
    /* Array of oscillators */
    output wavegen_t wave_gens[`N_OSCILLATORS]
);

    /* Wires and internal registers */
    synth_t conf;
    logic[0:$bits(synth_t)/WIDTH-1] [WIDTH-1:0]buffer  = '{default:0}; // TODO: make packed

    integer counter = 0;

    assign volume = conf.volume;
    assign reverb = conf.reverb;

    for (genvar i = 0; i < `N_OSCILLATORS; i++) begin
        assign wave_gens[i] = conf.wave_gens[i];
    end

    /* Print buffer as a memory map */
    function void print_mem(input logic[WIDTH-1:0][0:$bits(synth_t)/WIDTH-1] buffer);
`ifdef DEBUG
        $display("[cu] Address map of synth_t at %t", $time());
        for (int i = 0; i < $size(buffer); i += 8) begin
            automatic string prt = $sformatf("[cu] %04x:", i);
            for (int ii = 0; ii < 8; ii++) begin
                if (ii > 0 && ii % 4 == 0) prt = {prt, " |"};
                prt = {prt, $sformatf(" %02x", buffer[i+ii])};
            end
            $display("%s", prt);
        end
`endif
    endfunction


    always_ff @ (posedge(clk)) begin
        if (!rstn) begin
            reset_synth_t(conf);
            //conf <= synth_t'('{default:0});
            buffer <= '{default:0};
        end
        else if (enable) begin
            if (counter < $size(buffer)) begin
                buffer[counter] <= sig_in;
                counter <= counter + 1;
                $display("[cu] Recieved sig_in = 0x%02x. counter = %d", sig_in, counter);
                print_mem(buffer);
                print_synth_t(synth_t'(buffer));
            end
            else begin
                /* Cast to synth_t struct. Might have to be done as an explicit function due to
                byte alignment e.g. of enums in structure sent from mcu */
                conf <= synth_t'(buffer);
            end
        end
        else begin
            
            //$display("Recieved struct:");
        end
    end
endmodule