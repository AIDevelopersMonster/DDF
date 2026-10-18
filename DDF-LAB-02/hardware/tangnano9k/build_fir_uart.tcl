# Gowin Education 1.9.9Beta-4 legacy CLI. Keep baseline FIR RTL unchanged.
set root [file dirname [file normalize [info script]]]
set lab_dir [file normalize [file join $root .. ..]]
set build_dir [file join $root build fir_uart]
file mkdir $build_dir
cd $build_dir

if {[catch {
    set_device GW1NR-LV9QN88PC6/I5
    add_file [file join $lab_dir rtl moving_average4.v]
    add_file [file join $root rtl ddf_uart_rx.v]
    add_file [file join $root rtl ddf_uart_tx.v]
    add_file [file join $root rtl top_fir_uart.v]
    add_file [file join $root constraints top_fir_uart.cst]
    add_file [file join $root constraints top_fir_uart.sdc]
    set_option -top_module top_fir_uart
    set_option -output_base_name fir_uart9k
    set_option -synthesis_tool gowinsynthesis
    puts "DDF_FIR_UART_BUILD_START"
    run all
} err opts]} {
    puts stderr "DDF_FIR_UART_BUILD_ERROR: $err"
    puts stderr [dict get $opts -errorinfo]
    exit 1
}
set bitstream [file join $build_dir impl pnr fir_uart9k.fs]
if {![file exists $bitstream] || [file size $bitstream] == 0} {
    puts stderr "DDF_FIR_UART_BUILD_ERROR: .fs missing or empty"
    exit 2
}
puts "DDF_FIR_UART_BITSTREAM_READY"
puts [file normalize $bitstream]
exit 0
