`timescale 1ns / 1ps

// Serial Peripheral Interface peripheral (slave) module
// `mosi`   - master out, slave in, or `sdi` (serial data in)
// `miso`   - master in, slave out, or `sdo` (serial data out)
// `sclk`   - master clock
// `clk`    - internal clock
// `csn`    - chip select, active low
// `recv`   - recieving register
// `send`   - sending register
// `irq`    - signal word transmitted/output valid

module spi_slave #(parameter WIDTH = 32) (
    input mosi,
    output miso,

    input sclk,
    input clk,
    input csn,

    output [WIDTH-1:0] recv,
    input[WIDTH-1:0] send,

    output output_valid
);
    wire [WIDTH-1:0] out;
    reg rstn = 1;
    wire output_valid;
    wire enable = ~csn;
    // SIPO for incomming data
    sipo_shift_register #(.WIDTH(WIDTH)) sipo0 (
        .in(mosi),
        .clk(sclk),
        .rstn(rstn), // Drives 0 as long as chip is not selected
        .out(recv),
        .enable(enable),
        .output_valid(output_valid)
    );

    // TODO: Implement miso
    // PISO for outgoing data
    // piso_shift_register sh_send #(.WIDTH(WIDTH)) (
    //     .in(send),
    //     .clk(sclk),
    //     .rstn(csn),
    //     .out(miso)
    // );

    always @(posedge clk) begin
        // TODO: Use internal clock to signal output ready
        //$display("recv = %d, output_valid = ", recv, output_valid);
    end    

endmodule