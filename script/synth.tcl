set_param general.maxThreads 32

set_part xc7z020clg400-1

read_verilog [glob ../design/*.v]

set_property ip_repo_paths ../vivado-library [current_project]
update_ip_catalog

file mkdir ./ip/dvi2rgb
file copy -force ../ip/dvi2rgb.xci ./ip/dvi2rgb/
read_ip ./ip/dvi2rgb/dvi2rgb.xci
set locked [get_property IS_LOCKED [get_ips dvi2rgb]]
set upgrade [get_property UPGRADE_VERSIONS [get_ips dvi2rgb]]
if {$upgrade != "" && $locked} {
    upgrade_ip [get_ips dvi2rgb]
}
generate_target all [get_ips dvi2rgb]
synth_ip [get_ips dvi2rgb]

file mkdir ./ip/rgb2dvi
file copy -force ../ip/rgb2dvi.xci ./ip/rgb2dvi/
read_ip ./ip/rgb2dvi/rgb2dvi.xci
set locked [get_property IS_LOCKED [get_ips rgb2dvi]]
set upgrade [get_property UPGRADE_VERSIONS [get_ips rgb2dvi]]
if {$upgrade != "" && $locked} {
    upgrade_ip [get_ips rgb2dvi]
}
generate_target all [get_ips rgb2dvi]
synth_ip [get_ips rgb2dvi]

set VIN_FREQ $::env(FREQ)
read_xdc [glob ../constr/zybo-z7-20.xdc]
synth_design -top top \
    -generic H_WIDTH=$::env(H_WIDTH) \
    -generic H_START=$::env(H_START) \
    -generic H_TOTAL=$::env(H_TOTAL) \
    -generic V_HEIGHT=$::env(V_HEIGHT) \
    -generic KH=$::env(KH) \
    -generic KV=$::env(KV)
write_checkpoint -force post_synth.dcp
report_timing_summary -file report/timing_syn.rpt
report_utilization -file report/util_syn.rpt
