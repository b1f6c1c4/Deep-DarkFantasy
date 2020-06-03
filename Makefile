VIVADO?=vivado
DESIGN=$(wildcard design/*.v)
CONSTR=$(wildcard constr/*.xdc)

program: script/program.tcl build/output.bit
	cd build/ && $(VIVADO) -mode tcl -source $<

build/output.bit: script/run.tcl $(DESIGN) $(CONSTR)
	mkdir -p build/
	cd build/ && $(VIVADO) -mode tcl -source $<

.PHONY: program
