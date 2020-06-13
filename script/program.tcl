open_hw_manager
connect_hw_server -url localhost:3121
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/210351A82051A]
open_hw_target

current_hw_device [get_hw_devices xc7z020_1]
refresh_hw_device -update_hw_probes false [get_hw_devices xc7z020_1]
set_property PROGRAM.FILE {output.bit} [get_hw_devices xc7z020_1]
# set_property PROBES.FILE {output.ltx} [get_hw_devices xc7z020_1]

program_hw_devices [get_hw_devices xc7z020_1]
refresh_hw_device [get_hw_devices xc7z020_1]
