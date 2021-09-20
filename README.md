# FPGA

Codebase for FPGA part of synthesizer computer project. HDL synthesized and implemented using Vivado tcl toolchain.

## Build
* Add sources in `build.tcl`, using the `read_verilog` keyword.
* Makefile contains the full command to start Vivado and run build script, run `make [all]`.

## Program
* After building and successfully generating bitstream, connect board and run `make program`.
* Makefile contains the full command to start Vivado and run `program.tcl`.

## Resources

Xilincs video intro to using Vivado in batch mode [here](https://www.youtube.com/watch?v=04uFCkR5owM).

Vivado Tcl reference guide, [UG835](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_1/ug835-vivado-tcl-commands.pdf).

