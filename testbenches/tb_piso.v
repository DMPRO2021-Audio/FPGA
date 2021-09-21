`timescale 1ns / 1ps

module tb_piso;

    reg clk;
    reg rstn;
    reg enable;
    reg [31:0] data_in;
    reg [31:0] data_out;

    wire sd;

    initial rstn = 1;
    initial enable = 1;
    initial clk = 0;
    initial data_in = 32'h0;

    always #10 clk = ~clk;

    piso_shift_register #(.WIDTH(32)) piso(
        .in(data_in),
        .out(sd),
        .clk(clk),
        .rstn(rstn),
        .enable(enable)
    );

    always @ (posedge(clk)) begin
        data_out <= (sd << 31) | (data_out >> 1);
        $display("At time = %g: data_in = %b, data_out = %b", $time, data_in, data_out);
    end

    initial begin
        #20;
        data_in <= 32'hf0f0f0f0;
        #620;
        $display("First data register shifted");
        $display("At time = %g: data_in = %b, data_out = %b", $time, data_in, data_out);
        #640;
        $display("Second data register shifted");
        $display("At time = %g: data_in = %b, data_out = %b", $time, data_in, data_out);

        $display("Resetting");
        rstn <= 0;
        #20;
        data_in <= 32'h0000000f;
        #20;
        #20;
        rstn <= 1;
        $display("Reset done");
        #640;

        $display("At time = %4g: data_in = %b, data_out = %b", $time, data_in, data_out);
        $finish;
    end

endmodule