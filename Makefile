VIVADO?=vivado
DESIGN=$(wildcard design/*.v)
CONSTR=$(wildcard constr/*.xdc)
XCI=$(wildcard ip/*.xci)

program: script/program.tcl build/output.bit
	cd build/ && $(VIVADO) -mode batch -source ../$<

build/output.bit: script/run.tcl $(DESIGN) $(CONSTR) $(XCI)
	mkdir -p build/
	cd build/ && $(VIVADO) -mode batch -source ../$<

.PHONY: program
