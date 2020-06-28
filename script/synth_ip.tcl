source ../script/common.tcl

set_part $::env(PART)

set_property ip_repo_paths ../vivado-library [current_project]
update_ip_catalog

set name $::env(IP_NAME)

read_ip ./ip/$name/$name.xci
generate_target all [get_ips $name]
synth_ip [get_ips $name]
