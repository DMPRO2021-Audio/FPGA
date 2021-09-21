#
# BUILD SCRIPT
#

# Get design name from arguments
set design_name [lindex $argv 0]
# Get output directory from arguments
set output_dir [lindex $argv 2]

# Assemble project

# Sources
read_verilog [glob ./rtl_modules/shift_registers/sipo_register.v]
read_verilog [glob ./rtl_modules/spi_slave.v]
read_verilog [glob ./rtl_modules/top.v]

# Board constaints file
read_xdc ./constraints/Arty-A7-35-Master.xdc

# Other constraints
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]


# Synthesis and implementation

set ARTYA735T "xc7a35ticsg324-1L"

# Synthesis

synth_design -name $design_name -verilog_define DEBUG=1 -top top -part $ARTYA735T
# Write checkpoint and report
write_checkpoint -force $output_dir/post_synth
report_utilization -file $output_dir/post_synth_util.rpt
report_timing -sort_by group -max_paths 5 -path_type summary -file $output_dir/post_synth_timing.rpt
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


# Generate reports

report_timing_summary -file $output_dir/post_route_timing_summary.rpt
report_timing -sort_by group -max_paths 100 -path_type summary -file $output_dir/post_route_timing.rpt
report_utilization -file $output_dir/post_route_util.rpt
report_drc -file $output_dir/post_impl_drc.rpt
write_verilog -force $output_dir/post_impl_netlist.v
write_xdc -no_fixed_only -force $output_dir/post_impl.xdc


# Generate bitstream

write_bitstream -force -file $output_dir/program.bit
