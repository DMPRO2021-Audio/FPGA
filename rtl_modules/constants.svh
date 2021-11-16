// Define system wide constants

`ifndef CLK_FRQ
`define CLK_FRQ 100_000_000
`endif

`ifndef N_OSCILLATORS
`define N_OSCILLATORS 32
`endif

`ifndef ENVELOPE_LEN
`define ENVELOPE_LEN 8
`endif

`ifndef SAMPLE_RATE
`define SAMPLE_RATE 48000
`endif

`ifndef MIN_FREQUENCY
`define MIN_FREQUENCY 16
`endif

`ifndef MAX_SAMPLES_PER_PERIOD
`define MAX_SAMPLES_PER_PERIOD `SAMPLE_RATE / `MIN_FREQUENCY
`endif

`ifndef SPI_WIDTH
`define SPI_WIDTH 8
`endif

`define ENVELOPE_RESET_BIT 0
`define WAVEGEN_ENABLE_BIT 1

`define N_WAVETABLES 2
`define SAMPLE_WIDTH 24             // Width of samples when sent to DAC
`define FIXED_POINT 8               // Fixed decimal precision for internal computation
// Convert and round a fixed precision decimal to a sample width int
`define FIXED_POINT_TO_SAMPLE_WIDTH(val) (`SAMPLE_WIDTH'((signed'(val + val[`FIXED_POINT-1])) >>> `FIXED_POINT))
`define REAL_TO_FIXED_POINT(val) int'(val * (1 <<< `FIXED_POINT))
`define SF (1 <<< `FIXED_POINT)     // Scaling Factor

// Maximum length of variable fifos in filters, will affect their space consumption.
// A length of 1440 with sample rate as clock gives a delay of 30 ms
`ifndef MAX_FILTER_FIFO_LENGTH
`define MAX_FILTER_FIFO_LENGTH 1024 * 8
`endif
