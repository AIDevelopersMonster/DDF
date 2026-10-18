# DDF-LAB-02: Gowin legacy CLI synthesis

set script_dir [file dirname [file normalize [info script]]]
set lab_dir [file dirname $script_dir]
set rtl_file [file normalize [file join $lab_dir rtl moving_average4.v]]
set build_dir [file join $lab_dir build gowin_syn]

file mkdir $build_dir
cd $build_dir

foreach cmd {set_device add_file set_option run} {
    if {[llength [info commands $cmd]] == 0} {
        puts stderr "DDF_MISSING_COMMAND: $cmd"
        exit 2
    }
}

if {[catch {
    set_device GW1NR-LV9QN88PC6/I5
    add_file $rtl_file

    set_option -top_module moving_average4
    set_option -output_base_name ddf_lab02
    set_option -synthesis_tool gowinsynthesis

    puts "DDF_GOWIN_SYN_START"
    run syn
} err opts]} {
    puts stderr "DDF_GOWIN_ERROR: $err"
    puts stderr [dict get $opts -errorinfo]
    exit 1
}

puts "DDF_GOWIN_SYN_COMMAND_COMPLETED"
exit 0
