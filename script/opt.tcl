set_param general.maxThreads 8

open_checkpoint post_synth.dcp

read_xdc [glob ../constr/debug.xdc]

opt_design
write_checkpoint -force post_opt.dcp
