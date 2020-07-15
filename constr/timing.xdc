set VIN_PERIOD [expr {double(round(1e6/$VIN_FREQ))/1000}]
set VIN_HPERIOD [expr {double(round(5e5/$VIN_FREQ))/1000}]

create_clock -period $VIN_PERIOD -name hdmi0_in_clk_p -waveform [list 0.000 $VIN_HPERIOD] [get_ports hdmi0_in_clk_p]
create_clock -period $VIN_PERIOD -name hdmi1_in_clk_p -waveform [list 0.000 $VIN_HPERIOD] [get_ports hdmi1_in_clk_p]

set_false_path -through [get_nets i_rotary/out[*]]
set_false_path -through [get_nets */i_overlay/mode[*]]
set_false_path -through [get_nets */i_overlay/en]
