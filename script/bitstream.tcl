open_checkpoint post_route.dcp

write_bitstream -force output.bit
if {[llength [get_debug_cores]] > 0} {
    write_debug_probes -force output.ltx
} else {
    file delete output.ltx
}
