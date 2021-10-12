
`timescale 1ns / 1ps

`include "constants.svh"

import protocol_pkg::*;
import shape_pkg::*;

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

localparam CLK_PERIOD = 1000;
localparam SCLK_PERIOD = CLK_PERIOD * 48;
always #(CLK_PERIOD/2) clk=~clk;
always #(SCLK_PERIOD/2) sclk=~sclk;

integer i;

initial begin
    $dumpfile("tb_top.vcd");
    $dumpvars(0, tb_top);
end

// initial begin
//     repeat(6) #(SCLK_PERIOD) $display("leds: %b", led);
// end
function void print_mem(input logic[0:$bits(synth_t)/8-1][7:0] buffer);
`ifdef DEBUG
    $display("[cu] Address map of synth_t at %t", $time());
    for (int i = 0; i < $size(buffer); i += 8) begin
        case ($size(buffer) - i)
            1:  $display("[cu] %04x: %02x", i, buffer[i]);
            2:  $display("[cu] %04x: %02x %02x", i, buffer[i], buffer[i+1]);
            3:  $display("[cu] %04x: %02x %02x %02x", i, buffer[i], buffer[i+1], buffer[i+2]);
            4:  $display("[cu] %04x: %02x %02x %02x %02x", i, buffer[i], buffer[i+1], buffer[i+2], buffer[i+3]);
            5:  $display("[cu] %04x: %02x %02x %02x %02x | %02x", i, buffer[i], buffer[i+1], buffer[i+2], buffer[i+3], buffer[i+4]);
            6:  $display("[cu] %04x: %02x %02x %02x %02x | %02x %02x", i, buffer[i], buffer[i+1], buffer[i+2], buffer[i+3], buffer[i+4], buffer[i+5]);
            7:  $display("[cu] %04x: %02x %02x %02x %02x | %02x %02x %02x", i, buffer[i], buffer[i+1], buffer[i+2], buffer[i+3], buffer[i+4], buffer[i+5], buffer[i+6]);
            default: begin
                $display("[cu] %04x: %02x %02x %02x %02x | %02x %02x %02x %02x", i, buffer[i], buffer[i+1], buffer[i+2], buffer[i+3], buffer[i+4], buffer[i+5], buffer[i+6], buffer[i+7]);
            end
        endcase
    end
`endif
endfunction

initial begin
    //bit[63:0]msg = 64'h dead_beef_1234_5678; // message
    synth_t msg;
    logic[0:$bits(synth_t)/8-1][7:0] buffer;
    reset_synth_t(msg);
    
    msg.reverb = 32'hfeedbac4;
    msg.volume = 32'hdeadbeef;
    msg.wave_gens[0].freq = 32'h01234567;
    msg.wave_gens[1].freq = 32'h89abcdef;
    msg.wave_gens[2].freq = 32'hbebafa11;
    msg.wave_gens[3].freq = 32'habba1337;
    msg.wave_gens[0].shape = SAWTOOTH;
    msg.wave_gens[1].shape = SIN;
    msg.wave_gens[2].shape = SQUARE;
    msg.wave_gens[3].shape = SAMPLE_NAME;

    for (int i = 0; i < `N_OSCILLATORS; i++) begin
        for (int ii = 0; ii < `ENVELOPE_LEN; ii++) begin
            msg.wave_gens[i].envelopes[ii].rate = 32'h12349001;
            msg.wave_gens[i].envelopes[ii].duration = 32'h42005678;
        end
    end

    $display("Sending struct:");
    print_synth_t(msg);

    buffer = msg;
    //buffer = '{default:8'h42};
    /* Simulate PISO shift register, serialize and send message */
    $display("[tb_top] Sending %d bits", $bits(msg));
    for (i = 0; i < $bits(msg)/8; i++) begin
        $display("Sending %02x", buffer[i]);
        for (int j = 0; j < 8; j++) begin
            #(SCLK_PERIOD) csel = 0;
            mosi = buffer[i][j];
        end
    end
    #(SCLK_PERIOD) csel = 1;

    $display("Done sending %d bits to synth_t (%d bits)", $bits(msg), $bits(synth_t));
    print_synth_t(msg);
    print_mem(buffer);
    #(SCLK_PERIOD*2) $finish;
end

endmodule