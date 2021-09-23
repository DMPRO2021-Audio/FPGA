
// Serial in Parallel out shift register
//  Signals output_valid on the clock cycle
//  when the out register is full. Receices
//  LSB first.
// - parameter WIDTH: Size of register

module sipo_shift_register #(parameter WIDTH = 32) (
    input in,
    output logic [WIDTH-1:0] out,
    output output_valid,
    input clk, rstn, enable
);
    logic [7:0] counter = 0;

    assign output_valid = enable && !counter; //(0 == WIDTH - counter) ? 1 : 0;

    always @(posedge clk) begin
        if (!rstn) begin
            out <= 0;
            counter <= 0;
        end
        else begin
            if (enable) begin
`ifdef DEBUG
                $display("shift in %d. counter = %d", in, counter);
`endif
                out[WIDTH-1] <= in;
                for (int i = WIDTH - 1; i > 0; i = i - 1) begin
                    out[i-1] <= out[i];
                end
                counter <= (counter + 1) % WIDTH;
            end
        end
    end
endmodule

