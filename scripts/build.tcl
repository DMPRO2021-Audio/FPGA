#
# BUILD SCRIPT
#

set where [file dirname [info script]]

# Get design name from arguments
set design_name [lindex $argv 0]
set source_dir [lindex $argv 1]
set constr_dir [lindex $argv 2]
set synth_dir [lindex $argv 3]
# Get output directory from arguments
set output_dir [lindex $argv 4]
set synth_only [lindex $argv 5]

### Assemble project ###

# ! Add sources here
read_verilog -sv [glob $source_dir/shift_registers/sipo_register.sv]
read_verilog -sv [glob $source_dir/spi_slave.sv]
read_verilog -sv [glob $source_dir/fifo_delay.sv]
read_verilog -sv [glob $source_dir/top.sv]

# ! 

# Board constaints file
read_xdc $constr_dir/Arty-A7-35-Master.xdc

# Other constraints
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]


### Synthesis and implementation ###

set ARTYA735T "xc7a35ticsg324-1L"

# Synthesis

synth_design -name $design_name -verilog_define DEBUG=1 -top top -part $ARTYA735T
# Write checkpoint and report
write_checkpoint -force $output_dir/post_synth
report_utilization -file $output_dir/post_synth_util.rpt
report_timing -sort_by group -max_paths 5 -path_type summary -file $output_dir/post_synth_timing.rpt

if {$synth_only == 1} { exit 0 }

# Debug ILA cores
source [file join $where insert_ila.tcl]
# Optimize
opt_design
power_opt_design
# Placement
place_design
# Write checkpoint
write_checkpoint -force $output_dir/post_place
phys_opt_design
# Route
route_design
# Write checkpoint
write_checkpoint -force $output_dir/post_place


### Generate reports ###

report_timing_summary -file $output_dir/post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $output_dir/post_route_timing.rpt
report_utilization -file $output_dir/post_route_util.rpt
report_drc -file $output_dir/post_impl_drc.rpt
write_verilog -force $output_dir/post_impl_netlist.v
write_xdc -no_fixed_only -force $output_dir/post_impl.xdc


### Generate bitstream ###

write_bitstream -force -file $output_dir/program.bit
