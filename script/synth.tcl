set_param general.maxThreads 8

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

set VIN_FREQ $::env(FREQ)
read_xdc [glob ../constr/timing.xdc]
synth_design -top top \
    -generic H_WIDTH=$::env(H_WIDTH) \
    -generic H_START=$::env(H_START) \
    -generic H_TOTAL=$::env(H_TOTAL) \
    -generic V_HEIGHT=$::env(V_HEIGHT) \
    -generic KH=$::env(KH) \
    -generic KV=$::env(KV) \
    -generic SMOOTH_T=$::env(SMOOTH_T) \
    -generic OVERLAY_WIDTH=$::env(OVERLAY_WIDTH) \
    -generic OVERLAY_XMIN=$::env(OVERLAY_XMIN) \
    -generic OVERLAY_XMAX=$::env(OVERLAY_XMAX) \
    -generic OVERLAY_YMIN=$::env(OVERLAY_YMIN) \
    -generic OVERLAY_YMAX=$::env(OVERLAY_YMAX)
write_checkpoint -force post_synth.dcp
report_timing_summary -file report/timing_syn.rpt
report_utilization -file report/util_syn.rpt
