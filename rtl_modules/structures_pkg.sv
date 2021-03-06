`timescale 1ns / 1ps
`include "constants.svh"

package shape_pkg;
    typedef enum logic [7:0]{
        SAWTOOTH = 0,
        SQUARE = 1,         
        SIN = 2,           
        PIANO = 3,
        PAN_FLUTE = 4,
        GUITAR = 5
    } wave_shape;
endpackage
package protocol_pkg;
    //---------------------------------------------------------------------------------------------/
    // Definition of protocol for communication between MCU and FPGA
    //---------------------------------------------------------------------------------------------/
    import shape_pkg::*;

    typedef struct packed {
        logic signed [15:0] rate /* FIXED POINT * 2*/;
        logic [7:0] duration;
    } envelope_t;

    typedef struct packed {
        logic [31:0] freq /* FIXED POINT */;
        logic [31:0] velocity;
        envelope_t [0:`ENVELOPE_LEN-1] envelopes;
        wave_shape shape;
        logic [7:0] cmds;
    } wavegen_t;

    // typedef struct packed {
    //     logic [31:0] delay;
    //     logic [31:0] feedback;
    // } echo_t;

    typedef struct packed {
        logic signed [31:0] balance /* FIXED POINT */;
    } pan_t;

    // typedef struct packed {
    //     logic [31:0] playback_volume;
    //     logic [7:0] playback_speed;
    //     logic [7:0] cmds;
    // } looper_t;

    typedef struct packed {
        // Tau values are delays. 0, 1, 2 and 3 are for comb filters, selected in a 1:1.5 range where
        // the smallest determines the initial delay. Tau 4 and 5 are for all-pass filters, usually
        // set to 5ms and 1.7 ms. Tau is computed as time [ms] * sample rate
        // Gain values are always < 1.0. 0, 1, 2 and 3 are for comb filters = 10 ^ (-3 t / T), where
        // T is the reverb time.
        logic signed [0:5][31:0] tau;
        logic signed [0:6][31:0] gain /* FIXED POINT */;
    } reverb_t;

    typedef struct packed {
        wavegen_t [0:`N_OSCILLATORS-1] wave_gens;
        logic [31:0] master_volume;
        reverb_t reverb;
        pan_t pan;
        // looper_t looper;
        // echo_t echo;
    } synth_t;

    function automatic void reset_synth_t(output synth_t synth);
        synth.reverb.tau = '{default:0};
        synth.reverb.gain = '{default:0};
        synth.master_volume = 0;
        synth.reverb = '{default:0};
        synth.pan    = '{default:0};
        for (int i = 0; i < `N_OSCILLATORS; i++) begin
            synth.wave_gens[i].freq = 0;
            synth.wave_gens[i].shape = SIN;
            synth.wave_gens[i].velocity = 0;
            synth.wave_gens[i].cmds = 0;
            for (int ii = 0; ii < `ENVELOPE_LEN; ii++) begin
                synth.wave_gens[i].envelopes[ii].rate = 0;
                synth.wave_gens[i].envelopes[ii].duration = 0;
            end
        end
    endfunction

    function void print_synth_t(input synth_t synth);
`ifdef DEBUG
        $display("synth_t {");
        $display("\t.reverb: %x", synth.reverb);
        $display("\t.volume: %x", synth.master_volume);
        $display("\t.pan: pan_t { .balance: %x }", synth.pan.balance);
        $display("\t.looper: looper_t { .playback_volume: %x, .playback_speed: %x, .cmds: %x }", 
            synth.looper.playback_volume, synth.looper.playback_speed, synth.looper.cmds);
        $display("\t.echo: echo_t { .delay: %x, .feedback: %x }", 
            synth.echo.delay, synth.echo.feedback);

        for (int i = 0; i < `N_OSCILLATORS; i++) begin
            $display("\t.wave_gens[%02d]: wavegen_t {", i);
            $display("\t\t.freq: %x", synth.wave_gens[i].freq);
            $display("\t\t.velocity: %x", synth.wave_gens[i].velocity);
            $display("\t\t.shape: %x", synth.wave_gens[i].shape);
            $display("\t\t.cmds: %x", synth.wave_gens[i].cmds);
            $display("\t\t.envelopes: [");
            for (int ii = 0; ii < `ENVELOPE_LEN; ii++) begin
                $display("\t\t\tenvelope_t { .rate: %x, .duration: %x }", 
                    synth.wave_gens[i].envelopes[ii].rate, 
                    synth.wave_gens[i].envelopes[ii].duration);
            end
            $display("\t\t]");
            $display("\t}");
        end
        $display("}");
`endif // def DEBUG
    endfunction

    function void print_wavegen_t(input wavegen_t wavegen);
            $display("\t.wavegen_t {");
            $display("\t\t.freq: %x", wavegen.freq);
            $display("\t\t.velocity: %x", wavegen.velocity);
            $display("\t\t.shape: %x", wavegen.shape);
            $display("\t\t.cmds: %x", wavegen.cmds);
            $display("\t\t.envelopes: [");
            for (int ii = 0; ii < `ENVELOPE_LEN; ii++) begin
                $display("\t\t\tenvelope_t { .rate: %x, .duration: %x }", 
                    wavegen.envelopes[ii].rate, 
                    wavegen.envelopes[ii].duration);
            end
            $display("\t\t]");
            $display("\t}");
    endfunction

endpackage