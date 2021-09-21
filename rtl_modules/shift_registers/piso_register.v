`timescale 1ns / 1ps
module piso_shift_register #(
    parameter WIDTH = 32
)(
    input [WIDTH - 1:0] in,
    output out,

    input clk,
    input rstn,
    input enable
);

    reg [WIDTH - 1:0] register;
    reg [$clog2(WIDTH):0] counter;

    initial register = 0;
    initial counter = 0;

    assign out = register[0];

    always @ (posedge(clk)) begin
        if(!rstn) begin
            register <= in;
            counter <= 0;
        end

        if(enable && rstn) begin
            if(counter == WIDTH - 1) begin
                register <= in;
                counter <= 0;
            end else begin
                register <= register >> 1;
                counter <= counter + 1;
            end
        end
    end

endmodule