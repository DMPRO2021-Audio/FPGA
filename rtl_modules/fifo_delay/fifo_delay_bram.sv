`timescale 1ns/1ps

module fifo_delay_bram #(
    parameter WIDTH = 32,
    parameter MAXLEN = 1024
)(
    input logic clk,                    // Unused
    input logic sample_clk,             // Rate at which data is propagated trough queue
    input logic enable,
    input logic [31:0] len,
    input logic [WIDTH-1:0] in,
    output logic [WIDTH-1:0] out = 0,
    /* DEBUG */
    output logic [32*3-1:0] debug
);
    logic [$clog2(MAXLEN)-1:0] ridx = 1, widx = 0, init = 0; // Read and write index, and init
    logic [WIDTH-1:0] out_reg, in_reg;

    /* DEBUG */
    logic [15:0] _ridx, _widx;
    logic [31:0] rw;
    assign _ridx = ridx;
    assign _widx = widx;
    assign rw = {_ridx[15:0], _widx[15:0]};

    BRAM_inst #(
        .DATA_WIDTH (WIDTH),
        .ADDR_WIDTH ($clog2(MAXLEN))
    ) queue (
        .data_in    (in_reg),
        .read_addr  (ridx),
        .write_addr (widx),
        .wr_en      (enable),
        .clk        (sample_clk),
        .data_out   (out_reg)
    );

    always_ff @ ( posedge sample_clk ) begin
        debug <= {in, out, rw};
        if (enable) begin
            widx <= (widx + 1) % len;
            ridx <= (widx + 2) % len;
            if (init < len+1) begin
                in_reg <= 0;
                /* Protect against uninitialized data by forcing zero until any real data has had
                the chance to reach through */
                init <= init + 1;
                out <= 0;
            end
            else begin
                out <= out_reg;
                in_reg <= in;
            end
        end
    end

endmodule