set scripts_dir [file dirname [info script]]

# Get design name from arguments
set design_name [lindex $argv 0]
set source_dir [lindex $argv 1]
set constr_dir [lindex $argv 2]
set synth_dir [lindex $argv 3]
# Get output directory from arguments
set output_dir [lindex $argv 4]
set synth_only [lindex $argv 5]

### Assemble project ###

# ! Packages needed by other compilation units loaded first
read_verilog -sv [glob $source_dir/structures_pkg.sv]

# ! Add sources here
read_verilog -sv [glob $source_dir/shift_registers/sipo_register.sv]
read_verilog -sv [glob $source_dir/spi_slave.sv]
read_verilog -sv [glob $source_dir/fifo_delay.sv]
read_verilog     [glob $source_dir/dac_transmitter.v]
read_verilog -sv [glob $source_dir/constants.svh]
read_verilog -sv [glob $source_dir/control_unit.sv]
read_verilog -sv [glob $source_dir/oscillator.sv]
read_verilog -sv [glob $source_dir/mixer.sv]
read_verilog -sv [glob $source_dir/pan.sv]

# Use this when using 48MHz clock
#read_verilog [glob $source_dir/clk_wiz/clk_wiz.v]  
# Use this when using 100MHz clock (devboard)
read_verilog [glob $source_dir/clk_wiz/clk_wiz_dev.v] 

# ! top is loaded last
read_verilog -sv [glob $source_dir/top.sv]

add_files [glob $source_dir/../lookup_tables/*]
# ! 

# Board constaints file
read_xdc $constr_dir/Arty-A7-35-Master.xdc

# Other constraints
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]


### Synthesis and implementation ###

set ARTYA735T "xc7a35ticsg324-1L"