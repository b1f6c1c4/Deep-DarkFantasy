source ../script/common.tcl

open_checkpoint post_opt.dcp

if {[file exists post_route.dcp]} {
    read_checkpoint -incremental post_route.dcp
}

read_xdc [glob ../constr/zybo-z7-20.xdc]

set_property IODELAY_GROUP dvi2rgb_iodelay_grp_0 [get_cells i_dark_0/i_dvi2rgb/U0/DataDecoders[*].DecoderX/InputSERDES_X/InputDelay]
set_property IODELAY_GROUP dvi2rgb_iodelay_grp_0 [get_cells i_dark_0/i_dvi2rgb/U0/TMDS_ClockingX/IDelayCtrlX]

set_property IODELAY_GROUP dvi2rgb_iodelay_grp_1 [get_cells i_dark_1/i_dvi2rgb/U0/DataDecoders[*].DecoderX/InputSERDES_X/InputDelay]
set_property IODELAY_GROUP dvi2rgb_iodelay_grp_1 [get_cells i_dark_1/i_dvi2rgb/U0/TMDS_ClockingX/IDelayCtrlX]

place_design -directive AltSpreadLogic_medium
write_checkpoint -force post_place.dcp
report_timing -file report/timing_place.rpt
