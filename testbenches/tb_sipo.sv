
module tb_sipo;
    reg clk = 0;
    always #5 clk = ~clk;
    reg rstn = 1;
    reg enable = 0;
    wire ready;

    reg [8-1:0] in_value = 0;
    reg serial = 0;
    integer i;
    wire [8-1:0] out_value;

    sipo_shift_register #(.WIDTH(8)) sipo0 (
        .clk(clk),
        .in(serial),
        .out(out_value),
        .output_valid(ready),
        .rstn(rstn),
        .enable(enable)
    );

    initial begin
        in_value = 8'b 10010110;
        
        $display("SIPO tb");
        enable = 1;
        for (i = 0; i < 8; i = i + 1) begin
            serial = in_value[i];
            #10 $display("out = %d, in = %d, output_valid = %d, enable = %d", out_value, in_value, ready, enable);
            if (ready && out_value != in_value) $error("ready signaled when output was not correct");
        end
        serial = 0;
        enable = 0;
        #10 $display("out = %d, in = %d, output_valid = %d, enable = %d", out_value, in_value, ready, enable);
        rstn = 0;
        #10 $display("out = %d, in = %d, output_valid = %d, enable = %d", out_value, in_value, ready, enable);
        rstn = 1;
        in_value = 8'b 11001001;
        #10 $display("out = %d, in = %d, output_valid = %d, enable = %d", out_value, in_value, ready, enable);
        enable = 1;
        for (i = 0; i < 8; i = i + 1) begin
            serial = in_value[i];
            #10 $display("out = %d, in = %d, output_valid = %d, enable = %d", out_value, in_value, ready, enable);
            if (ready && out_value != in_value) $error("ready signaled when output was not correct");
        end
        in_value = 8'b 00110110;
        for (i = 0; i < 8; i = i + 1) begin
            serial = in_value[i];
            #10 $display("out = %d, in = %d, output_valid = %d, enable = %d", out_value, in_value, ready, enable);
            if (ready && out_value != in_value) $error("ready signaled when output was not correct");
        end
        enable = 0;
        #10 $display("out = %d, in = %d, output_valid = %d, enable = %d", out_value, in_value, ready, enable);

        $finish;
    end
endmodule