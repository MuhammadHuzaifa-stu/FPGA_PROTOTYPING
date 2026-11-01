# scripts/build_hw.tcl

# 0. Maximize thread usage for 8 cores
set_param general.maxThreads 8

# Parse target passed via -tclargs (defaults to 'all')
set target "all"
if { $argc > 0 } {
    set target [lindex $argv 0]
}

# 1. Open existing Vivado project
open_project ./uBlaze/ublaze_mcs/ublaze_mcs.xpr

# 2. Re-generate targets for Block Designs (Clock Wizard & MCS CPU)
set bd_files [get_files *.bd]
if {[llength $bd_files] > 0} {
    generate_target all $bd_files
}

# 3. Read Hardware Constraints
add_files -fileset constrs_1 -noreuse ./hardware/constraints.xdc

# 4. Parse flist.f from hardware directory
set flist_path "./hardware/flist.f"
set fp [open $flist_path r]
set file_data [read $fp]
close $fp

set lines [split $file_data "\n"]
foreach line $lines {
    set line [string trim $line]
    
    # Skip empty lines and comments
    if {$line eq "" || [string match "//*" $line] || [string match "#*" $line]} {
        continue
    }
    
    if {[string match "+incdir+*" $line]} {
        set inc_dir [string range $line 8 end]
        set full_inc_dir [file normalize "./hardware/$inc_dir"]
        set_property include_dirs $full_inc_dir [current_fileset]
    } else {
        set sv_file [file normalize "./hardware/$line"]
        read_verilog -sv $sv_file
    }
}

# 5. Set Top Module
set_property top mcs_top_vanilla [current_fileset]
update_compile_order -fileset sources_1

# 6. Target Execution Logic
if {$target eq "synth" || $target eq "synthesis"} {
    puts "=== Running Synthesis ==="
    launch_runs synth_1 -jobs 8
    wait_on_run synth_1
} elseif {$target eq "impl" || $target eq "implementation"} {
    puts "=== Running Implementation ==="
    launch_runs impl_1 -jobs 8
    wait_on_run impl_1

} elseif {$target eq "bitstream" || $target eq "all" || $target eq "hw"} {
    puts "=== Running Synthesis, Implementation, and Bitstream Generation ==="
    launch_runs synth_1 -jobs 8
    wait_on_run synth_1
    
    launch_runs impl_1 -to_step write_bitstream -jobs 8
    wait_on_run impl_1

    file mkdir ./build
    write_hw_platform -fixed -force -file ./build/system.xsa

} else {
    puts "ERROR: Unknown target '$target'. Valid targets: synth, impl, bitstream, all"
    exit 1
}

exit