`include "constants.svh"

package shape_pkg;
    typedef enum logic [1:0]{
        SAWTOOTH = 0,
        SQUARE,         
        SIN,           
        SAMPLE_NAME     // Not implemented, this can be any sample
    } wave_shape;
endpackage
package protocol_pkg;
    //---------------------------------------------------------------------------------------------/
    // Definition of protocol for communication between MCU and FPGA
    //---------------------------------------------------------------------------------------------/
    import shape_pkg::*;

    typedef struct packed {
        logic [31:0] rate;
        logic [31:0] duration;
    } envelope_t;

    typedef struct packed {
        envelope_t [0:`ENVELOPE_LEN-1]envelopes;
        logic [31:0] freq;
        wave_shape shape;
    } wavegen_t;

    typedef struct packed {
        wavegen_t [0:`N_OSCILLATORS-1] wave_gens;
        logic [31:0] reverb;
        logic [31:0] volume;
    } synth_t;

    function void reset_synth_t(output synth_t synth);
        synth.reverb = 0;
        synth.volume = 0;
        for (int i = 0; i < `N_OSCILLATORS; i++) begin
            synth.wave_gens[i].freq = 0;
            synth.wave_gens[i].shape = SIN;
            for (int ii = 0; ii < `ENVELOPE_LEN; ii++) begin
                synth.wave_gens[i].envelopes[ii].rate = 0;
                synth.wave_gens[i].envelopes[ii].duration = 0;
            end
        end
    endfunction

endpackage