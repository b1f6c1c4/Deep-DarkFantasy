source ../script/common.tcl

open_checkpoint post_synth.dcp

read_xdc [glob ../constr/zybo-z7-20.xdc]

read_xdc [glob ../constr/debug.xdc]

opt_design -directive Explore
write_checkpoint -force post_opt.dcp
