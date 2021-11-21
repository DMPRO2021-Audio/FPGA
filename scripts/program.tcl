#
# FLASH DEVICE SCRIPT
# (only simple flashing of FPGA)
#

set scripts_dir [file dirname [info script]]
# ! Add sources in env_setup.tcl
source [file join $scripts_dir args_parse.tcl]

open_hw_manager

# Connect to Digilent Cable on localhost

connect_hw_server -url localhost:3121
# Assuming only 1 target is connected
current_hw_target [lindex [get_hw_targets] 0]
open_hw_target


# Program and refresh device
current_hw_device [lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [lindex [get_hw_devices] 0]

puts $output_dir/$design_name-$chip_v.bit

if {$perm_flash == 0} {
    # Volatile flash
    set_property PROGRAM.FILE $output_dir/$design_name-$chip_v.bit [lindex [get_hw_devices] 0]

    program_hw_devices [lindex [get_hw_devices] 0]
    refresh_hw_device [lindex [get_hw_devices] 0]
} else {
    # Program flash chip
    # Generate memory configuration
    write_cfgmem  -format mcs -size 16 -interface SPIx1 -loadbit "up 0x00000000 $output_dir/$design_name-$chip_v.bit" -checksum -force -file $output_dir/$design_name-$chip_v.mcs

    # Write memory configuration
    create_hw_cfgmem -hw_device [lindex [get_hw_devices] 0] [lindex [get_cfgmem_parts {s25fl128sxxxxxx0-spi-x1_x2_x4}] 0]
    set_property PROGRAM.BLANK_CHECK  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
    set_property PROGRAM.ERASE  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
    set_property PROGRAM.CFG_PROGRAM  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
    set_property PROGRAM.VERIFY  1 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
    set_property PROGRAM.CHECKSUM  0 [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
    refresh_hw_device [lindex [get_hw_devices] 0]

    set_property PROGRAM.ADDRESS_RANGE  {entire_device} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
    # set_property PROGRAM.ADDRESS_RANGE  {use_file} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
    set_property PROGRAM.FILES [list $output_dir/$design_name-$chip_v.mcs ] [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
    set_property PROGRAM.PRM_FILE {} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
    # or pull-up / pull-down
    set_property PROGRAM.UNUSED_PIN_TERMINATION {pull-none} [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
    
    startgroup 
    create_hw_bitstream -hw_device [lindex [get_hw_devices] 0] [get_property PROGRAM.HW_CFGMEM_BITFILE [ lindex [get_hw_devices] 0]]; program_hw_devices [lindex [get_hw_devices] 0]; refresh_hw_device [lindex [get_hw_devices] 0];
    # INFO: [Labtools 27-3164] End of startup status: HIGH
    # INFO: [Labtools 27-2302] Device xc7a35t (JTAG device index = 0) is programmed with a design that has 1 SPI core(s).
    program_hw_cfgmem -hw_cfgmem [ get_property PROGRAM.HW_CFGMEM [lindex [get_hw_devices] 0]]
    # Mfg ID : 1   Memory Type : 20   Memory Capacity : 18   Device ID 1 : 0   Device ID 2 : 0
    # Performing Erase Operation...
    # Erase Operation successful.
    # Performing Program and Verify Operations...
    # Program/Verify Operation successful.
    # INFO: [Labtoolstcl 44-377] Flash programming completed successfully
    program_hw_cfgmem: Time (s): cpu = 00:00:02 ; elapsed = 00:00:51 . Memory (MB): peak = 8434.078 ; gain = 2.000 ; free physical = 275 ; free virtual = 10250
    endgroup
}
