set_part xc7z100ffg900-2

read_verilog [glob ../design/*.v]
read_verilog [glob ../design/ip/i2c_master/*.v]

file mkdir ./ip/sys_pll
file copy -force ../ip/sys_pll.xci ./ip/sys_pll/
read_ip ./ip/sys_pll/sys_pll.xci
synth_ip [get_ips sys_pll]

read_xdc [glob ../constr/*.xdc]
synth_design -top top

opt_design
place_design
phys_opt_design
route_design
write_bitstream -force output.bit
