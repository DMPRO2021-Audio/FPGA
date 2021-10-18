// Define system wide constants

`ifndef CLK_FRQ
`define CLK_FRQ 100_000_000
`endif

`ifndef N_OSCILLATORS
`define N_OSCILLATORS 16
`endif

`ifndef ENVELOPE_LEN
`define ENVELOPE_LEN 8
`endif

`ifndef SAMPLE_RATE
`define SAMPLE_RATE 48000
`endif

`ifndef SPI_WIDTH
`define SPI_WIDTH 8
`endif

`ifndef CMD_BITS
`define ENVELOPE_RESET_BIT 0
`define WAVEGEN_ENABLE_BIT 1
`define CMD_BITS
`endif

`ifndef FIXED_POINTS
`define FIXED_POINTS
`define VOLUME_FIXED_POINT 10
`define FREQ_FIXED_POINT 10
`define REAL_TO_FREQ_FIXED_POINT(freq) int'(freq * (1 <<< `FREQ_FIXED_POINT))
`endif