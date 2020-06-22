set_param general.maxThreads 8

open_checkpoint post_synth.dcp

opt_design
write_checkpoint -force post_opt.dcp
