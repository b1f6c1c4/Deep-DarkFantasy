setws build/fsbl/

createhw -name fsbl_hw -hwspec ../system.hdf
createapp -name fsbl -app {Zynq MP FSBL} -proc psu_cortexa9_0 -hwproject fsbl_hw -os standalone
projects -build
exec bootgen -arch zynq -image output.bif -w -o BOOT.bin
