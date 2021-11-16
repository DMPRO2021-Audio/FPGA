set scripts_dir [file dirname [info script]]

# Get design name from arguments
set design_name [lindex $argv 0]
set source_dir [lindex $argv 1]
set constr_dir [lindex $argv 2]
set synth_dir [lindex $argv 3]
# Get output directory from arguments
set output_dir [lindex $argv 4]
set synth_only [lindex $argv 5]
set devkit [lindex $argv 6]
set opt [lindex $argv 7]
set chip_v [lindex $argv 8]

### Assemble project ###

# ! Packages needed by other compilation units loaded first
read_verilog -sv [glob $source_dir/structures_pkg.sv]

# ! Add sources here
read_verilog     [glob $source_dir/memory/wave_rom.v]
read_verilog -sv [glob $source_dir/shift_registers/sipo_register.sv]
read_verilog -sv [glob $source_dir/spi_slave.sv]
read_verilog     [glob $source_dir/dac_transmitter.v]
read_verilog -sv [glob $source_dir/constants.svh]
read_verilog -sv [glob $source_dir/control_unit.sv]
read_verilog -sv [glob $source_dir/filters/comb_filter.sv]
read_verilog -sv [glob $source_dir/filters/allpass_filter.sv]
read_verilog -sv [glob $source_dir/filters/reverberator_core.sv]
read_verilog -sv [glob $source_dir/fifo_delay/fifo_delay.sv]
read_verilog -sv [glob $source_dir/fifo_delay/fifo_delay_bram.sv]
read_verilog     [glob $source_dir/memory/bram.v]
read_verilog -sv [glob $source_dir/mixer.sv]
read_verilog -sv [glob $source_dir/oscillator.sv]
read_verilog -sv [glob $source_dir/pan.sv]

if {$devkit == 1} {
    # Use this when using 100MHz clock (devboard)
    read_verilog [glob $source_dir/clk_wiz/clk_wiz_dev.v] 
    # Board constaints file
    read_xdc $constr_dir/Arty-A7-35-Master.xdc
} else {
    # Use this when using 48MHz clock
    read_verilog [glob $source_dir/clk_wiz/clk_wiz.v]  
    # Board constaints file
    read_xdc $constr_dir/Custom-PCB.xdc
}


# ! top is loaded last
read_verilog -sv [glob $source_dir/top.sv]

add_files [glob $source_dir/../lookup_tables/*]
# ! 

# Other constraints
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]

set_property IS_ENABLED FALSE [get_drc_checks UTLZ-1]
set_property IS_ENABLED FALSE [get_drc_checks UTLZ-2]


### Synthesis and implementation ###

set ARTYA735T "xc7a35ticsg324-1L"
set ARTYA7100T "xc7a100tftg256-1"
set_param general.maxThreads 12