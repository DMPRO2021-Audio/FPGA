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
    input logic mosi,
    output logic miso,

    input sclk, clk, csn,

    output logic [WIDTH-1:0] recv,
    input logic [WIDTH-1:0] send,

    output logic output_valid
);

    assign miso = 1;

    logic rstn = 1;

    logic read = 0;
    logic reg_output_valid;
    assign output_valid = reg_output_valid && !read;

    logic enable;
    assign enable = ~csn;
    // SIPO for incomming data
    sipo_shift_register #(.WIDTH(WIDTH)) sipo0 (
        .in(mosi),
        .clk(sclk),
        .rstn(rstn), // Drives 0 as long as chip is not selected
        .out(recv),
        .enable(enable),
        .output_valid(reg_output_valid)
    );

    // TODO: Implement miso
    // PISO for outgoing data
    // piso_shift_register sh_send #(.WIDTH(WIDTH)) (
    //     .in(send),
    //     .clk(sclk),
    //     .rstn(csn),
    //     .out(miso)
    // );

    always_ff @(posedge clk) begin
        // TODO: Use internal clock to signal output
        if (reg_output_valid && !read) begin
            //output_valid <= 1;
            read <= 1;
            //$display("[spi] recv = %d, output_valid = %d", recv, output_valid);
        end
        else if (!reg_output_valid) begin
            read <= 0;
        end
    end

endmodule