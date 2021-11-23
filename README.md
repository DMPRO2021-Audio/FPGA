# FPGA

Codebase for FPGA part of synthesizer computer project 2021. HDL synthesized and implemented using Vivado tcl toolchain.

## Build
* Add sources in `build.tcl`, using the `read_verilog` keyword.
* Makefile contains the full command to start Vivado and run build script, run `make synth`.
* Flags are available for build options, like building for the Arty-35T or Arty100T. More information by running `make help`.
* Makefile also makes a separate build, much faster for debugging, simulation and quick testing.
* `make vivado` to open Vivado with environment setup.

### Waveforms
See `open_wave_config` and `open_wave_database` un user guide (UG835) on how to open waveforms created with `-wdb` flag.

## Program
* After building and successfully generating bitstream, connect board and run `make prog`.
* Makefile contains the full command to start Vivado and run `program.tcl`.

## Resources

* Xilincs video intro to using Vivado in batch mode [here](https://www.youtube.com/watch?v=04uFCkR5owM).
* Vivado Tcl reference guide, [UG835](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_1/ug835-vivado-tcl-commands.pdf).
* Artix FPGA online reference guide, [here](https://digilent.com/reference/programmable-logic/arty-a7/reference-manual).
