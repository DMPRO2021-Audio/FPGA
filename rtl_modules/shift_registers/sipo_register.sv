
// Serial in Parallel out shift register
//  Signals output_valid on the clock cycle
//  when the out register is full. Recieves
//  LSB first.
// - parameter WIDTH: Size of register

module sipo_shift_register #(parameter WIDTH = 32) (
    input logic in,
    output logic [WIDTH-1:0] out,
    output logic output_valid,
    input clk, rstn, enable
);
    logic [7:0] counter = 0;

    //assign output_valid = !(WIDTH - counter - 1) && enable;// enable && !counter; //

    always_ff @(posedge clk) begin
        if (!rstn) begin
            out <= 0;
            counter <= 0;
            output_valid <= 0;
        end
        else begin
            if (enable) begin
`ifdef DEBUG
                $display("[sipo] shift in %d. counter = %d. output_valid = %d. out = %02x", in, counter, output_valid, out);
`endif
                out[WIDTH-1] <= in;
                for (int i = WIDTH - 1; i > 0; i = i - 1) begin
                    out[i-1] <= out[i];
                end
                if (counter + 1 == WIDTH) begin
                    output_valid <= 1;
                end else begin
                    output_valid <= 0;
                end
                counter <= (counter + 1) % WIDTH;
            end
        end
    end
endmodule

