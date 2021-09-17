# FPGA

Codebase for FPGA part of synthesizer computer project. HDL synthesized and implemented using Vivado tcl toolchain.

## Build
* Add sources in `build.tcl`, using the `read_verilog` keyword.
* Makefile contains the full command to start Vivado and run build script, run `make [all]`.

## Program
* After building and successfully generating bitstream, connect board and run `make program`.
* Makefile contains the full command to start Vivado and run `program.tcl`.
