#
# Environment setup for synthesis and interactive sessions
#

set scripts_dir [file dirname [info script]]
# ! Add sources in env_setup.tcl
source [file join $scripts_dir args_parse.tcl]

# create_project -force -in_memory temp_proj
# set_property part $chip_v [current_project]
# set_property target_language verilog [current_project]

### Assemble project ###
# read_ip [glob $ip_dir/ila_0/ila_0.xci]
# generate_target {instantiation_template} [get_files *ila_0.xci]
# update_compile_order -fileset sources_1
# generate_target all [get_files  *ila_0.xci]
# synth_ip [get_files *ila_0.xci]

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

#read_ip [glob $ip_dir/ila.xci]
# generate_target
# Add ILA IP:
# create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0
# set_property -dict [list 
#     CONFIG.C_PROBE7_WIDTH {32} CONFIG.C_PROBE6_WIDTH {32} CONFIG.C_PROBE5_WIDTH {32} 
#     CONFIG.C_PROBE4_WIDTH {32} CONFIG.C_PROBE3_WIDTH {32} CONFIG.C_PROBE2_WIDTH {32} 
#     CONFIG.C_PROBE1_WIDTH {32} CONFIG.C_PROBE0_WIDTH {32} 
#     CONFIG.C_DATA_DEPTH {1024} CONFIG.C_NUM_OF_PROBES {8} CONFIG.ALL_PROBE_SAME_MU {true}
#     ] [get_ips ila_2]


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
