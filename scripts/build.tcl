#
# BUILD SCRIPT
#

set scripts_dir [file dirname [info script]]
# ! Add sources in env_setup.tcl
source [file join $scripts_dir env_setup.tcl]

# Synthesis
# -verilog_define DEBUG=1
puts $chip_v
synth_design -name $design_name -top top -part $chip_v
# Write checkpoint and report
write_checkpoint -force $output_dir/post_synth
report_utilization -file $output_dir/post_synth_util.rpt
report_utilization -hierarchical -hierarchical_depth 10 -append -file $output_dir/post_synth_util.rpt
report_timing -sort_by group -max_paths 5 -path_type summary -file $output_dir/post_synth_timing.rpt

if {$synth_only == 1} { exit 0 }

# Debug ILA cores
# source [file join $scripts_dir insert_ila.tcl]
# Optimize

if {$opt > 0} {
    opt_design
    power_opt_design
    report_utilization -file $output_dir/post_synth_opt_util.rpt
    report_utilization -hierarchical -hierarchical_depth 10 -append -file $output_dir/post_synth_opt_util.rpt
}
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
