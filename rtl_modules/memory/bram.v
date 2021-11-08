`timescale 1ns / 1ps

module BRAM_inst
#(
    parameter DATA_WIDTH=32,
	parameter ADDR_WIDTH=10
)
(
    input [(DATA_WIDTH-1):0] data_in,
    input [(ADDR_WIDTH-1):0] read_addr, write_addr,
    input wr_en, clk,
    output [(DATA_WIDTH-1):0] data_out
);

   	(* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
   	reg [ADDR_WIDTH-1:0] read_addr_reg;
   
   	always @ (posedge clk) begin
      	read_addr_reg <= read_addr; 
      
      	if (wr_en) begin
       		ram[write_addr] <= data_in;
     	end
   	end

   	assign data_out = ram[read_addr_reg];

endmodule