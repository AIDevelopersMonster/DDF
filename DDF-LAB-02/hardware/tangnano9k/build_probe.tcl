set root [file dirname [file normalize [info script]]]
set build_dir [file join $root build]

file mkdir $build_dir
cd $build_dir

if {[catch {
    set_device GW1NR-LV9QN88PC6/I5

    add_file [file join $root rtl top_probe.v]
    add_file [file join $root constraints top_probe.cst]
    add_file [file join $root constraints top_probe.sdc]

    set_option -top_module top_probe
    set_option -output_base_name probe9k
    set_option -synthesis_tool gowinsynthesis

    run all
} err opts]} {
    puts stderr "DDF_BUILD_ERROR: $err"
    puts stderr [dict get $opts -errorinfo]
    exit 1
}

set bitstream [file join $build_dir impl pnr probe9k.fs]

if {![file exists $bitstream] || [file size $bitstream] == 0} {
    puts stderr "DDF_BUILD_ERROR: Bitstream missing or empty"
    exit 2
}

puts "DDF_PROBE_BITSTREAM_READY"
puts $bitstream
exit 0
