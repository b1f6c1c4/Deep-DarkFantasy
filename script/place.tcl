source ../script/common.tcl

open_checkpoint post_opt.dcp

if {[file exists post_route.dcp]} {
    read_checkpoint -incremental post_route.dcp
}

read_xdc [glob ../constr/zybo-z7-20.xdc]

place_design -directive AltSpreadLogic_medium
write_checkpoint -force post_place.dcp
report_timing -file report/timing_place.rpt
