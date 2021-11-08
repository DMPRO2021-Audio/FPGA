`timescale 1ns/1ps

module fifo_delay_bram #(
    parameter WIDTH = 32, 
    parameter MAXLEN = 2048
)(
    input clk,
    input sample_clk, // Rate at which data is propagated trough queue
    input rstn,
    input enable, //write,
    input [31:0] len,
    input [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out
);
    logic [$clog2(MAXLEN)-1:0] ridx = 0, widx = 0, init = 0; // Read and write index
    logic [WIDTH-1:0] data_out;

    BRAM_inst #(
        .DATA_WIDTH(WIDTH),
        .ADDR_WIDTH($clog2(MAXLEN))
    ) queue (
        .data_in (in),
        .read_addr (ridx),
        .write_addr (widx),
        .wr_en (enable),
        .clk (clk),
        .data_out (data_out)
    );

    //assign out = out_reg;

    always_ff @ ( posedge sample_clk ) begin
        // $strobe("[fifo_bram] in = %x, widx = %x, ridx = %x, len = %x, out_reg = %x data_out = %x", in, widx, ridx, len, out_reg, data_out);
        if (enable) begin
            widx <= (widx + 1) % len;
            ridx <= (widx + 2) % len;
            if (init < len-1) begin
                /* Protect against uninitialized data by forcing zero until any real data has had 
                the chance to reach through */
                init <= init + 1;
                out <= 0;
            end
            else out <= data_out;
        end
    end

endmodule