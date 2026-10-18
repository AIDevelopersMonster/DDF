# DDF-LAB-02: implement synthesizable FIR + hardware BIST on Tang Nano 9K.
# Tested syntax family: Gowin Education 1.9.9Beta-4 (legacy set_device).
set root [file dirname [file normalize [info script]]]
set lab_dir [file normalize [file join $root .. ..]]
set build_dir [file join $root build fir_bist]
file mkdir $build_dir
cd $build_dir

if {[catch {
    set_device GW1NR-LV9QN88PC6/I5
    add_file [file join $lab_dir rtl moving_average4.v]
    add_file [file join $root rtl top_fir_bist.v]
    add_file [file join $root constraints top_fir_bist.cst]
    add_file [file join $root constraints top_fir_bist.sdc]
    set_option -top_module top_fir_bist
    set_option -output_base_name fir_bist9k
    set_option -synthesis_tool gowinsynthesis
    puts "DDF_FIR_BIST_BUILD_START"
    run all
} err opts]} {
    puts stderr "DDF_FIR_BIST_BUILD_ERROR: $err"
    puts stderr [dict get $opts -errorinfo]
    exit 1
}
set bitstream [file join $build_dir impl pnr fir_bist9k.fs]
if {![file exists $bitstream] || [file size $bitstream] == 0} {
    puts stderr "DDF_FIR_BIST_BUILD_ERROR: .fs missing or empty"
    exit 2
}
puts "DDF_FIR_BIST_BITSTREAM_READY"
puts [file normalize $bitstream]
exit 0
