

package protocol_pkg;
    //---------------------------------------------------------------------------------------------/
    // Definition of protocol for communication between MCU and FPGA
    //---------------------------------------------------------------------------------------------/
    import shape_pkg::*;

    typedef struct packed {
        logic [31:0] rate;
        logic [31:0] time;
    } envelope_t;

    typedef struct packed {
        envelope_t [`ENVELOPE_LEN] envelopes;
        logic [31:0] freq;
        wave_shape shape;
    } wavegen_t;

    typedef struct packed {
        wavegen_t [`N_OSCILLATORS] wave_gens;
        logic [31:0] reverb;
        logic [31:0] volume;
    } synth_t;

endpackage;