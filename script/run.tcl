set_part xc7z100ffg900-2
read_verilog [glob design/*.v]
# read_ip ip/sys_pll/sys_pll.xci
read_xdc [glob constr/*.xdc]
synth_design -top top
opt_design
place_design
phys_opt_design
route_design
write_bitstream -force output.bit
exit
