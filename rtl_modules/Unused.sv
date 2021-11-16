integer counter = 0;
    logic half_clk = 0;
    logic quarter_clk = 0; */
    // assign gpio[0] = half_clk;
    // assign gpio[4] = spi_csn;
    // //assign gpio[2] = spi_mosi;
    // always_ff @( negedge sys_clk ) begin
    //     half_clk <= ~half_clk;
    //     if (half_clk) begin
    //         if (spi_csn) begin
    //             gpio[1] <= ~spi_csn;
    //             gpio[1] <= counter < $bits(synth_t) ? 0 : 1; // csn_out
    //             gpio[2] <= counter < $bits(synth_t) ? synth[counter] : 0;
    //             //gpio[2] <= counter < $bits(synth_t) ? hard[counter] : 0;
    //             counter <= (counter + 1) % ($bits(synth_t) + 32);
    //         end else begin
    //             counter <= 0;
    //             gpio[1] <= 1;
    //         end 
    //     end
    // end
    // assign gpio[3] = sample_clk;
    // assign gpio[4] = sys_clk;
    // assign gpio[5] = sys_clk;
    // assign gpio[6] = sys_clk;
    // assign gpio[7] = sys_clk;
    //assign gpio = synth.wave_gens[0].freq[23:16];

    `ifdef NODEF
    /* Note values C3 to B5 */
    integer n[62];
    initial n = '{
        `REAL_TO_FIXED_POINT(65.406),   // C2       0
        `REAL_TO_FIXED_POINT(69.296),   // C#/Db2
        `REAL_TO_FIXED_POINT(73.416),   // D2
        `REAL_TO_FIXED_POINT(77.782),   // D#/Eb2
        `REAL_TO_FIXED_POINT(82.407),   // E2
        `REAL_TO_FIXED_POINT(87.307),   // F2
        `REAL_TO_FIXED_POINT(92.499),   // F#/Gb2
        `REAL_TO_FIXED_POINT(97.999),   // G2
        `REAL_TO_FIXED_POINT(103.826),  // G#/Ab2
        `REAL_TO_FIXED_POINT(110.000),  // A2
        `REAL_TO_FIXED_POINT(116.541),  // A#/Bb2
        `REAL_TO_FIXED_POINT(123.471),  // B2

        `REAL_TO_FIXED_POINT(130.813),  // C3       12
        `REAL_TO_FIXED_POINT(138.591),  // C#/Db3
        `REAL_TO_FIXED_POINT(146.832),  // D3
        `REAL_TO_FIXED_POINT(155.563),  // D#/Eb3
        `REAL_TO_FIXED_POINT(164.814),  // E3
        `REAL_TO_FIXED_POINT(174.614),  // F3
        `REAL_TO_FIXED_POINT(184.997),  // F#/Gb3
        `REAL_TO_FIXED_POINT(195.998),  // G3
        `REAL_TO_FIXED_POINT(207.652),  // G#/Ab3
        `REAL_TO_FIXED_POINT(220.000),  // A3
        `REAL_TO_FIXED_POINT(233.082),  // A#/Bb3
        `REAL_TO_FIXED_POINT(246.942),  // B3

        `REAL_TO_FIXED_POINT(261.626),  // C4       24
        `REAL_TO_FIXED_POINT(277.183),  // C#/Db4
        `REAL_TO_FIXED_POINT(293.665),  // D4
        `REAL_TO_FIXED_POINT(311.127),  // D#/Eb4
        `REAL_TO_FIXED_POINT(329.628),  // E4
        `REAL_TO_FIXED_POINT(349.228),  // F4
        `REAL_TO_FIXED_POINT(369.994),  // F#/Gb4
        `REAL_TO_FIXED_POINT(391.995),  // G4
        `REAL_TO_FIXED_POINT(415.305),  // G#/Ab4
        `REAL_TO_FIXED_POINT(440.000),  // A4
        `REAL_TO_FIXED_POINT(466.164),  // A#/Bb4
        `REAL_TO_FIXED_POINT(493.883),  // B4

        `REAL_TO_FIXED_POINT(523.251),  // C5       36
        `REAL_TO_FIXED_POINT(554.365),  // C#/Db5
        `REAL_TO_FIXED_POINT(587.330),  // D5
        `REAL_TO_FIXED_POINT(622.254),  // D#/Eb5
        `REAL_TO_FIXED_POINT(659.255),  // E5
        `REAL_TO_FIXED_POINT(698.456),  // F5
        `REAL_TO_FIXED_POINT(739.989),  // F#/Gb5
        `REAL_TO_FIXED_POINT(783.991),  // G5
        `REAL_TO_FIXED_POINT(830.609),  // G#/Ab5
        `REAL_TO_FIXED_POINT(880.000),  // A5
        `REAL_TO_FIXED_POINT(932.328),  // A#/Bb5
        `REAL_TO_FIXED_POINT(987.767),  // B5

        `REAL_TO_FIXED_POINT(1046.502), // C6       48
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000),  //
        `REAL_TO_FIXED_POINT(0.00000)   //
    };
    /* Setup global synth varables */
    initial begin
        synth.pan.balance = `REAL_TO_FIXED_POINT(0);
        synth.master_volume = `REAL_TO_FIXED_POINT(1);
    end

    /* Initialize oscillators */
    initial begin
        integer i;

        for(i = 0; i < `N_OSCILLATORS; i++) begin
            synth.wave_gens[i].velocity = 500000;
            synth.wave_gens[i].shape = PIANO;
            synth.wave_gens[i].freq = n[12 + i*2];
            synth.wave_gens[i].cmds = 0 << `ENVELOPE_RESET_BIT | 1 << `WAVEGEN_ENABLE_BIT;

            synth.wave_gens[i].envelopes[0].gain = 0;
            synth.wave_gens[i].envelopes[0].duration = 5;

            synth.wave_gens[i].envelopes[1].gain = 8'hff;
            synth.wave_gens[i].envelopes[1].duration = 5;

            synth.wave_gens[i].envelopes[2].gain = 212;
            synth.wave_gens[i].envelopes[2].duration = 10;

            synth.wave_gens[i].envelopes[3].gain = 176;
            synth.wave_gens[i].envelopes[3].duration = 20;

            synth.wave_gens[i].envelopes[4].gain = 8'h80;
            synth.wave_gens[i].envelopes[4].duration = 2 * 20;

            synth.wave_gens[i].envelopes[5].gain = 128;
            synth.wave_gens[i].envelopes[5].duration = 3 * 20;

            synth.wave_gens[i].envelopes[6].gain = 64;
            synth.wave_gens[i].envelopes[6].duration = 3 * 40;

            synth.wave_gens[i].envelopes[7].gain = 64;
            synth.wave_gens[i].envelopes[7].duration = 0;
        end
        synth.wave_gens[2].velocity = 600000;
    end

    /* Sample tunes */

    // /* Start 'Tilbake til Normalen' monotonic */
    // integer tbt_normalen_pitch[54] = '{28, 29, 31, 31, 33, 28, 24, 24, 21, 21, 24, 24, 26, 27, 26, 24, 31, 31, 31, 33, 34, 33, 34, 33, 31, 49, 28, 29, 31, 31, 31, 33, 28, 24, 24, 21, 21, 24, 24, 26, 27, 26, 24, 24, 29, 29, 29, 31, 28, 24, 24, 21, 24, 49};
    // // length in 8ths
    // integer tbt_normalen_len[54]   = '{1,  1,  2,  1,  1,  1,  1,  1, 1, 1,  1,  1,  1,  1,  1,  2,  1,  1,  1,  1,  1,  1,  1,  1,  2,  4,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, 1, 1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1, 4,  4 };
    // integer tbt_normalen_tempo = 116 * 2; // 116 bpm to 8ths
    // initial synth.wave_gens[0].freq = tbt_normalen_pitch[0];
    // /* End 'Tilbake til Normalen' monotonic */

    /* Start 'O bli hos meg' polyphonic */
    integer o_bli_hos_meg_p1[40] = '{31, 31, 29, 27, 34, 36, 34, 34, 32, 31, 31, 32, 34, 36, 34, 32, 29, 31, 33, 34, 31, 31, 29, 27, 34, 34, 32, 32, 31, 29, 29, 31, 32, 31, 29, 27, 32, 31, 29, 27 };
    integer o_bli_hos_meg_l1[40] = '{4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  4,  4,  2,  2,  2,  2,  8 , 4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  2,  2,  2,  2,  4,  4,  8  };
    integer o_bli_hos_meg_p2[40] = '{27, 26, 26, 27, 27, 24, 26, 27, 29, 27, 27, 27, 27, 27, 27, 27, 29, 27, 27, 26, 27, 26, 26, 27, 27, 27, 27, 28, 28, 29, 26, 27, 26, 27, 26, 24, 29, 27, 26, 22 };
    //integer o_bli_hos_meg_l2[40] = '{4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  4,  4,  2,  2,  2,  2,  8 , 4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  2,  2,  2,  2,  4,  4,  8  };

    integer o_bli_hos_meg_p3[42] = '{22, 22, 20, 19, 15, 15, 22, 22, 22, 22, 22, 20, 19, 20, 19, 24, 22, 22, 15, 17, 19, 20, 22, 20, 19, 27, 26, 24, 24, 24, 22, 20, 22, 22, 22, 22, 20, 19, 24, 22, 20, 19 };
    integer o_bli_hos_meg_l3[42] = '{4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  2,  2,  2,  2,  4,  2,  2,  2,  2,  2,  2,  8,  4,  2,  2,  2,  2,  2,  2,  6,  2,  8  };

    integer o_bli_hos_meg_p4[41] = '{15, 10, 10, 12, 7,  8,  10, 12, 14, 15, 15, 14, 12, 10, 8,  15, 17, 14, 15, 12, 10, 15, 10, 10, 12, 7,  8,  10, 12, 12, 17, 20, 19, 17, 15, 10, 12, 8,  10, 10, 15 };
    integer o_bli_hos_meg_l4[41] = '{4,  2,  2,  4,  4,  2,  2,  2,  2,  8,  2,  2,  2,  2,  4,  4,  2,  2,  2,  2,  8,  4,  2,  2,  4,  4,  3,  1,  2,  2,  8,  4,  2,  2,  2,  2,  2,  2,  4,  4,  8  };
    integer o_bli_hos_meg_tempo = 132;

    integer counter1 = 0;
    integer counter2 = 0;
    integer counter3 = 0;
    integer idx1 = 0;
    integer idx2 = 0;
    integer idx3 = 0;
    /* End 'O bli hos meg' polyphonic */
    always @(posedge sample_clk) begin
        if (counter1 >= (`SAMPLE_RATE * 60 / o_bli_hos_meg_tempo) * o_bli_hos_meg_l1[idx1]) begin
            counter1 <= 0;
            idx1 <= (idx1 + 1) % 40;
            synth.wave_gens[0].cmds <= synth.wave_gens[0].cmds | 1 << `ENVELOPE_RESET_BIT;
            synth.wave_gens[1].cmds <= synth.wave_gens[1].cmds | 1 << `ENVELOPE_RESET_BIT;
        end
        else begin
            synth.wave_gens[0].cmds <= synth.wave_gens[0].cmds & ~(1 << `ENVELOPE_RESET_BIT);
            synth.wave_gens[1].cmds <= synth.wave_gens[1].cmds & ~(1 << `ENVELOPE_RESET_BIT);
            synth.wave_gens[0].freq <= n[o_bli_hos_meg_p1[idx1]];
            synth.wave_gens[1].freq <= n[o_bli_hos_meg_p2[idx1]];
            counter1 <= counter1 + 1;
        end
        if (counter2 >= (`SAMPLE_RATE * 60 / o_bli_hos_meg_tempo) * o_bli_hos_meg_l4[idx2]) begin
            counter2 <= 0;
            idx2 <= (idx2 + 1) % 41;
            synth.wave_gens[2].cmds <= synth.wave_gens[2].cmds | 1 << `ENVELOPE_RESET_BIT;
        end
        else begin
            synth.wave_gens[2].cmds <= synth.wave_gens[2].cmds & ~(1 << `ENVELOPE_RESET_BIT);
            synth.wave_gens[2].freq <= n[o_bli_hos_meg_p4[idx2]];
            counter2 <= counter2 + 1;
        end
        if (counter3 >= (`SAMPLE_RATE * 60 / o_bli_hos_meg_tempo) * o_bli_hos_meg_l3[idx3]) begin
            counter3 <= 0;
            idx3 <= (idx3 + 1) % 42;
            synth.wave_gens[3].cmds <= synth.wave_gens[3].cmds | 1 << `ENVELOPE_RESET_BIT;
        end
        else begin
            synth.wave_gens[3].cmds <= synth.wave_gens[3].cmds & ~(1 << `ENVELOPE_RESET_BIT);
            synth.wave_gens[3].freq <= n[o_bli_hos_meg_p3[idx3]];
            counter3 <= counter3 + 1;
        end
    end
    /* End sample tunes */
/////////////
`endif

    // synth_t hard;
    // initial begin
    //     for (int i = 0; i < `N_OSCILLATORS; i++) begin
    //         hard.wave_gens[i].freq = 32'h1f3f5f7f;
    //         hard.wave_gens[i].velocity = 32'd500000;
    //         for (int j = 0; j < `ENVELOPE_LEN; j++) begin
    //             hard.wave_gens[i].envelopes[j].gain = 8'(i);
    //             hard.wave_gens[i].envelopes[j].duration = 8'(j);
    //         end
    //         hard.wave_gens[i].shape = SAWTOOTH;
    //         hard.wave_gens[i].cmds = 8'd10;
    //     end
    //     hard.master_volume = 32'd550000;
    //     hard.reverb.tau = {32'h1010, 32'h2020, 32'h3030, 32'h4040, 32'h5050, 32'h6060};
    //     hard.reverb.gain = {32'h7070, 32'h8080, 32'h9090, 32'ha0a0, 32'hb0b0, 32'hc0c0, 32'hd0d0};
    //     hard.pan.balance = 32'd0;
    // end

// "Large hall"
    // logic signed [31:0] tau[6] = {
    //     3003, 3403, 3905, 4495, 241, 83
    // };
    // logic signed [31:0] gain[7] = {
    //     `REAL_TO_FIXED_POINT(0.895),
    //     `REAL_TO_FIXED_POINT(0.883),
    //     `REAL_TO_FIXED_POINT(0.867),
    //     `REAL_TO_FIXED_POINT(0.853),
    //     `REAL_TO_FIXED_POINT(0.7),
    //     `REAL_TO_FIXED_POINT(0.7),
    //     `REAL_TO_FIXED_POINT(0.7)
    // };


    



    // ALL:
