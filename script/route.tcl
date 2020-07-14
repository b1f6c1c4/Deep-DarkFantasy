source ../script/common.tcl

open_checkpoint post_place.dcp

phys_opt_design
route_design -directive Explore

write_checkpoint -force post_route.dcp
report_route_status -file report/route_status.rpt

report_timing_summary -file report/timing_summary.rpt
report_timing -setup -nworst 10 -file report/setup_violations.rpt
report_timing -hold -nworst 10 -file report/hold_violations.rpt

report_power -advisory -file report/power_route.rpt
report_utilization -file report/util_route.rpt
report_drc -file report/drc_route.rpt

write_bitstream -force output.bit
if {[llength [get_debug_cores]] > 0} {
    write_debug_probes -force output.ltx
} else {
    file delete output.ltx
}
