open_checkpoint post_route.dcp

write_bitstream -force output.bit
if {[llength [get_debug_cores]] > 0} {
    write_debug_probes -force output.ltx
} else {
    file delete output.ltx
}

if {[llength [info commands write_hw_platform]] > 0} {
   write_hw_platform -force -include_bit output.xsa
} else {
   write_hwdef -force output.hdf
   write_sysdef -force system.hdf
}
