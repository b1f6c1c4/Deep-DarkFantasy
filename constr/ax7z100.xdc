# General settings

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]


# System main clock: 200MHz

create_clock -period 5.000 [get_ports clk_i_p]
set_property PACKAGE_PIN F9 [get_ports clk_i_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_i_p]


# System main reset

set_property PACKAGE_PIN D21 [get_ports rst_ni]
set_property IOSTANDARD LVCMOS33 [get_ports rst_ni]


# LED

set_property PACKAGE_PIN AJ16 [get_ports {led_o[0]}]
set_property PACKAGE_PIN AK16 [get_ports {led_o[1]}]
set_property PACKAGE_PIN AE16 [get_ports {led_o[2]}]
set_property PACKAGE_PIN AE15 [get_ports {led_o[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led_o[*]}]


# Button

set_property PACKAGE_PIN AF18 [get_ports {button_ni[0]}]
set_property PACKAGE_PIN AF17 [get_ports {button_ni[1]}]
set_property PACKAGE_PIN AH17 [get_ports {button_ni[2]}]
set_property PACKAGE_PIN AH16 [get_ports {button_ni[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {button_ni[*]}]


# Fan

set_property PACKAGE_PIN AG16 [get_ports fan_no]
set_property IOSTANDARD LVCMOS33 [get_ports fan_no]


# HDMI out: (through ADV7511)

set_property PACKAGE_PIN E15 [get_ports vout_scl_io]
set_property PACKAGE_PIN E16 [get_ports vout_sda_io]
set_property IOSTANDARD LVCMOS18 [get_ports {vout_scl_io vout_sda_io}]
set_property SLEW FAST [get_ports {vout_scl_io vout_sda_io}]
set_property PULLUP true [get_ports {vout_scl_io vout_sda_io}]

set_property PACKAGE_PIN H14 [get_ports vout_clk_o]
set_property IOSTANDARD LVCMOS18 [get_ports vout_clk_o]
set_property SLEW FAST [get_ports vout_clk_o]
set_property DRIVE 16 [get_ports vout_clk_o]

set_property PACKAGE_PIN G12 [get_ports vout_de_o]
set_property PACKAGE_PIN H13 [get_ports vout_hs_o]
set_property PACKAGE_PIN J13 [get_ports vout_vs_o]
set_property IOSTANDARD LVCMOS18 [get_ports {vout_de_o vout_hs_o vout_vs_o}]
set_property IOB TRUE [get_ports {vout_de_o vout_hs_o vout_vs_o}]
set_property SLEW FAST [get_ports {vout_de_o vout_hs_o vout_vs_o}]

set_property PACKAGE_PIN F12 [get_ports {vout_data_o[0]}]
set_property PACKAGE_PIN B11 [get_ports {vout_data_o[1]}]
set_property PACKAGE_PIN C11 [get_ports {vout_data_o[2]}]
set_property PACKAGE_PIN B12 [get_ports {vout_data_o[3]}]
set_property PACKAGE_PIN C12 [get_ports {vout_data_o[4]}]
set_property PACKAGE_PIN C13 [get_ports {vout_data_o[5]}]
set_property PACKAGE_PIN C14 [get_ports {vout_data_o[6]}]
set_property PACKAGE_PIN A12 [get_ports {vout_data_o[7]}]
set_property PACKAGE_PIN A13 [get_ports {vout_data_o[8]}]
set_property PACKAGE_PIN J14 [get_ports {vout_data_o[9]}]
set_property PACKAGE_PIN L14 [get_ports {vout_data_o[10]}]
set_property PACKAGE_PIN L15 [get_ports {vout_data_o[11]}]
set_property PACKAGE_PIN C16 [get_ports {vout_data_o[12]}]
set_property PACKAGE_PIN D16 [get_ports {vout_data_o[13]}]
set_property PACKAGE_PIN A17 [get_ports {vout_data_o[14]}]
set_property PACKAGE_PIN B17 [get_ports {vout_data_o[15]}]
set_property PACKAGE_PIN E17 [get_ports {vout_data_o[16]}]
set_property PACKAGE_PIN F17 [get_ports {vout_data_o[17]}]
set_property PACKAGE_PIN G16 [get_ports {vout_data_o[18]}]
set_property PACKAGE_PIN G17 [get_ports {vout_data_o[19]}]
set_property PACKAGE_PIN H16 [get_ports {vout_data_o[20]}]
set_property PACKAGE_PIN J16 [get_ports {vout_data_o[21]}]
set_property PACKAGE_PIN C17 [get_ports {vout_data_o[22]}]
set_property PACKAGE_PIN B16 [get_ports {vout_data_o[23]}]
set_property IOSTANDARD LVCMOS18 [get_ports {vout_data_o[*]}]
set_property IOB TRUE [get_ports {vout_data_o[*]}]
set_property SLEW FAST [get_ports {vout_data_o[*]}]
set_property DRIVE 8 [get_ports {vout_data_o[*]}]


# HDMI in: SI9011

set_property PACKAGE_PIN AC23 [get_ports vin_scl_io]
set_property PACKAGE_PIN AC22 [get_ports vin_sda_io]
set_property IOSTANDARD LVCMOS33 [get_ports {vin_scl_io vin_sda_io}]
set_property PULLUP true [get_ports {vin_scl_io vin_sda_io}]

set_property PACKAGE_PIN AD23 [get_ports vin_clk_i]
set_property IOSTANDARD LVCMOS33 [get_ports vin_clk_i]

set_property PACKAGE_PIN AB21 [get_ports vin_rst_no]
set_property IOSTANDARD LVCMOS33 [get_ports vin_rst_no]

set_property PACKAGE_PIN AF24 [get_ports vin_de_i]
set_property PACKAGE_PIN AE21 [get_ports vin_hs_i]
set_property PACKAGE_PIN AD21 [get_ports vin_vs_i]
set_property IOSTANDARD LVCMOS33 [get_ports {vin_de_i vin_hs_i vin_vs_i}]
set_property IOB TRUE [get_ports {vin_de_i vin_hs_i vin_vs_i}]

set_property PACKAGE_PIN AF23 [get_ports {vin_data_i[0]}]
set_property PACKAGE_PIN AE23 [get_ports {vin_data_i[1]}]
set_property PACKAGE_PIN AD24 [get_ports {vin_data_i[2]}]
set_property PACKAGE_PIN AC24 [get_ports {vin_data_i[3]}]
set_property PACKAGE_PIN AA24 [get_ports {vin_data_i[4]}]
set_property PACKAGE_PIN AB24 [get_ports {vin_data_i[5]}]
set_property PACKAGE_PIN Y22 [get_ports {vin_data_i[6]}]
set_property PACKAGE_PIN Y23 [get_ports {vin_data_i[7]}]
set_property PACKAGE_PIN AA22 [get_ports {vin_data_i[8]}]
set_property PACKAGE_PIN AA23 [get_ports {vin_data_i[9]}]
set_property PACKAGE_PIN AJ24 [get_ports {vin_data_i[10]}]
set_property PACKAGE_PIN AJ23 [get_ports {vin_data_i[11]}]
set_property PACKAGE_PIN AJ21 [get_ports {vin_data_i[12]}]
set_property PACKAGE_PIN AK21 [get_ports {vin_data_i[13]}]
set_property PACKAGE_PIN AK23 [get_ports {vin_data_i[14]}]
set_property PACKAGE_PIN AK22 [get_ports {vin_data_i[15]}]
set_property PACKAGE_PIN AH24 [get_ports {vin_data_i[16]}]
set_property PACKAGE_PIN AH23 [get_ports {vin_data_i[17]}]
set_property PACKAGE_PIN AJ20 [get_ports {vin_data_i[18]}]
set_property PACKAGE_PIN AK20 [get_ports {vin_data_i[19]}]
set_property PACKAGE_PIN AH21 [get_ports {vin_data_i[20]}]
set_property PACKAGE_PIN AG21 [get_ports {vin_data_i[21]}]
set_property PACKAGE_PIN AG20 [get_ports {vin_data_i[22]}]
set_property PACKAGE_PIN AF20 [get_ports {vin_data_i[23]}]
set_property IOB TRUE [get_ports {vin_data_i[*]}]
set_property IOSTANDARD LVCMOS33 [get_ports {vin_data_i[*]}]

create_clock -period 6.748 -name vin_clk_i -waveform {0.000 3.374} [get_ports vin_clk_i]
set_input_delay -clock [get_clocks vin_clk_i] -min -add_delay 1.010 [get_ports {vin_data_i[*]}]
set_input_delay -clock [get_clocks vin_clk_i] -max -add_delay 2.500 [get_ports {vin_data_i[*]}]
set_input_delay -clock [get_clocks vin_clk_i] -min -add_delay 1.010 [get_ports vin_de_i]
set_input_delay -clock [get_clocks vin_clk_i] -max -add_delay 2.500 [get_ports vin_de_i]
set_input_delay -clock [get_clocks vin_clk_i] -min -add_delay 1.010 [get_ports vin_hs_i]
set_input_delay -clock [get_clocks vin_clk_i] -max -add_delay 2.500 [get_ports vin_hs_i]
set_input_delay -clock [get_clocks vin_clk_i] -min -add_delay 1.010 [get_ports vin_vs_i]
set_input_delay -clock [get_clocks vin_clk_i] -max -add_delay 2.500 [get_ports vin_vs_i]
