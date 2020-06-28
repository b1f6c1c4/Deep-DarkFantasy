source ../script/common.tcl

open_checkpoint post_synth.dcp

read_xdc [glob ../constr/debug.xdc]

opt_design
write_checkpoint -force post_opt.dcp
