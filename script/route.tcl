set_param general.maxThreads 32

open_checkpoint post_place.dcp

phys_opt_design
route_design

write_checkpoint -force post_route.dcp
report_timing_summary -file report/timing_summary.rpt
report_route_status -file report/route_status.rpt
