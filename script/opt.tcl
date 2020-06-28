set_param general.maxThreads 8

open_checkpoint post_synth.dcp

if {[file exists ./debug.xdc]} {
   read_xdc [glob ./debug.xdc]
}

opt_design
write_checkpoint -force post_opt.dcp
