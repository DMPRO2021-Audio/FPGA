module tb_spi;

    reg clk = 0;
    always #5 clk <= ~clk;

    reg csn = 1;
    reg mosi;
    wire miso;

    reg[7:0] msg = 8'd 136;

    wire [7:0] out;
    reg [7:0] ignore;

    wire output_valid;


    spi_slave #(.WIDTH(8)) spi0 (
        .sclk(clk),
        .clk(clk),
        .mosi(mosi),
        .miso(miso),
        .csn(csn),
        .recv(out),
        .send(ignore),
        .output_valid(output_valid)
    );

    integer i;

    initial begin
        csn <= 0;
        for (i = 0; i < 8; i = i + 1) begin
            mosi <= msg[i];
            #10 $display("Sent bit %d. out = %d, output_valid = ", msg[i], out, output_valid);
        end
        $display("Message sent. out = %d, output_valid = ", out, output_valid);
        csn <= 1;
        #10 $display("Message sent. out = %d, output_valid = ", out, output_valid);
        #10 $display("Message sent. out = %d, output_valid = ", out, output_valid);
        #10 $display("Message sent. out = %d, output_valid = ", out, output_valid);

        #5 $finish;
    end

endmodule