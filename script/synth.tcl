source ../script/common.tcl

set_part $::env(PART)

set_property ip_repo_paths ../vivado-library [current_project]
update_ip_catalog

read_verilog [glob ../design/*.v]

set names [split $::env(IP_NAMES)]
if {[llength $names] > 0} {
   read_ip $names
   generate_target all [get_ips *]
   synth_ip [get_ips *]
}

set_property IS_ENABLED 0 [get_files [glob ./ip/dvi2rgb_1080p/src/ila*.xdc]]
set_property IS_ENABLED 0 [get_files [glob ./ip/dvi2rgb_1080p/src/ila*/*.xdc]]
set_property IS_ENABLED 0 [get_files [glob ./ip/dvi2rgb_1080p/src/ila*/*/*/*.xdc]]

set VIN_FREQ $::env(FREQ)
read_xdc [glob ../constr/timing.xdc]
synth_design -top deep \
    -generic H_WIDTH=$::env(H_WIDTH) \
    -generic H_START=$::env(H_START) \
    -generic H_TOTAL=$::env(H_TOTAL) \
    -generic V_HEIGHT=$::env(V_HEIGHT) \
    -generic KH=$::env(KH) \
    -generic KV=$::env(KV) \
    -generic SMOOTH_T=$::env(SMOOTH_T)
write_checkpoint -force post_synth.dcp
report_timing_summary -file report/timing_syn.rpt
report_utilization -file report/util_syn.rpt
