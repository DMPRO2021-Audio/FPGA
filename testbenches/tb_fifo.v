module tb_fifo;
    reg clk = 0;
    always #5 clk = ~clk;
    reg resetn = 1;

    reg [11:0] in_value = 0;
    wire [11:0] out_value;
    fifo #(.WIDTH(12), .LEN(10)) fifo_0(
        .clk(clk), 
        .resetn(resetn), 
        .in(in_value), 
        .out(out_value)
        );

    initial begin
        #0 in_value = 12'h 1;
        $display("out = %d at time %t", out_value, $time);
        #10 in_value = 12'h 2;
        $display("out = %d at time %t", out_value, $time);
        #10 in_value = 12'h 3;
        $display("out = %d at time %t", out_value, $time);
        #10 in_value = 12'h 4;
        $display("out = %d at time %t", out_value, $time);
        #10 in_value = 12'h 5;
        $display("out = %d at time %t", out_value, $time);
        #10 in_value = 12'h x;
        $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #10 $display("out = %d at time %t", out_value, $time);
        #30 $finish;
    end

endmodule