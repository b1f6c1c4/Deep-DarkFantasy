set_param general.maxThreads 8

set_msg_config -id {[IP_Flow 19-4965]} -string "ila_" -new_severity INFO
set_msg_config -id {[Synth 8-7023]} -string "processing_system7" -new_severity INFO
set_msg_config -id {[Synth 8-3331]} -string "processing_system7" -new_severity INFO
set_msg_config -id {[Constraints 18-5210]} -new_severity INFO
set_msg_config -id {[Timing 38-164]} -new_severity INFO
set_msg_config -id {[Timing 38-127]} -string "sys_clk_pin" -new_severity INFO
set_msg_config -id {[Constraints 18-550]} -string "IBUF_LOW_PWR" -new_severity INFO
set_msg_config -id {[DRC REQP-1839]} -string "RAM" -new_severity INFO
set_msg_config -id {[Vivado 12-750]} -new_severity INFO
set_msg_config -string "ila_pixclk" -new_severity INFO
set_msg_config -string "ila_refclk" -new_severity INFO
set_msg_config -string "ila_timing_workaround" -new_severity INFO
