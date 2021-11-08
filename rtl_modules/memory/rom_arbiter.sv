`timescale 1ns / 1ps

`include "constants.svh"

module rom_arbiter 
#(
    ADDR_WIDTH = $clog2(`MAX_SAMPLES_PER_PERIOD * `N_WAVETABLES),
    DATA_WIDTH = `SAMPLE_WIDTH + `FIXED_POINT,
    N_WAVEGENS = `N_OSCILLATORS
)
(
    input logic sys_clk,
    input logic [ADDR_WIDTH-1:0] addresses [N_WAVEGENS],

    output logic [DATA_WIDTH-1:0] out_data [N_WAVEGENS]
);

    logic rom_enable = 1;
    logic [ADDR_WIDTH-1:0] rom_addr;
    logic [DATA_WIDTH-1:0] rom_data;
    logic [$clog2(N_WAVEGENS)-1:0] index = 0;

    assign rom_addr = addresses[index];
    
    wave_rom rom(
        .clk(sys_clk),
        .en(rom_enable),
        .addr(rom_addr),
        .data(rom_data)
    );

    always_ff @(posedge sys_clk) begin
        out_data[index] <= rom_data;
        index <= (index + 1) % N_WAVEGENS;
    end

endmodule