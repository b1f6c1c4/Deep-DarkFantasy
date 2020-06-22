set_param general.maxThreads 32

set_part $::env(PART)

read_bd [glob ../fsbl/*.v]
generate_target all [get_ips *]

write_hwdef -force fsbl.hdf
write_sysdef -hwdef fsbl.hdf -bitfile fsbl.bit -force system.hdf
