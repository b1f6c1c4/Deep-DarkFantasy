setws .

createhw -name fsbl_hw -hwspec ../../system.hdf

createapp -name fsbl -app {Zynq FSBL} -proc ps7_cortexa9_0 -hwproject fsbl_hw -os standalone

configapp -app fsbl build-config release

projects -build
