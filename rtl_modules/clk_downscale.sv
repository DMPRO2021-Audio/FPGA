`timescale 1ps/1ps

/* Downscale a clk as closely as possible to an output clock */
module clk_downscale #(
    parameter FREQ_IN = 100_000_000,
    parameter FREQ_OUT = 48_000
) (
    input logic clk_in,
    output logic clk_out
);
    logic out = 0;
    integer scale = $rtoi(real'(FREQ_IN) / real'(FREQ_OUT) / 2.0);
    integer counter = 0;

    assign clk_out = out;
    
    always_ff @(posedge clk_in) begin
        if (counter >= scale - 1) begin
            out <= ~out;
            counter <= 0;
        end 
        else begin
            counter <= counter + 1;
        end
    end

endmodule
