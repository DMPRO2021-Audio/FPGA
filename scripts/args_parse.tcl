
# Parse tcl arguments into variables

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
set perm_flash [lindex $argv 8]
set chip_v [lindex $argv 9]

set ip_dir $output_dir/ip/$chip_v

# create_project -force -in_memory temp_proj
# set_property part $chip_v [current_project]
# set_property target_language verilog [current_project]
