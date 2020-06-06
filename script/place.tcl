open_checkpoint post_opt.dcp

if {[file exists post_route.dcp]} {
    read_checkpoint -incremental post_route.dcp
}
place_design
write_checkpoint -force post_place.dcp
report_timing -file report/timing_place.rpt
