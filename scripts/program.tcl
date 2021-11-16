# Program device
# puts "ILAs:"
# puts [get_hw_ilas]

set output_dir [lindex $argv 4]
open_hw_manager

# Connect to Digilent Cable on localhost

connect_hw_server -url localhost:3121
# Assuming only 1 target is connected
current_hw_target [lindex [get_hw_targets] 0]
open_hw_target


# Program and refresh device
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]

set_property PROGRAM.FILE $output_dir/program.bit [lindex [get_hw_devices] 0]

program_hw_devices [lindex [get_hw_devices] 0]
refresh_hw_device [lindex [get_hw_devices] 0]


# upload_hw_ila_data
# write_debug_probes