VIVADO?=vivado
DESIGN=$(wildcard design/*.v)
CONSTR=$(wildcard constr/*.xdc)
XCI=$(wildcard ip/*.xci)

program: script/program.tcl build/output.bit
	(cd build/ && $(VIVADO) -mode batch -source ../$< 2>&1) | ./script/log_highlight.sh

build/post_synth.dcp: script/synth.tcl $(DESIGN) $(CONSTR) $(XCI)
	(cd build/ && $(VIVADO) -mode batch -source ../$< 2>&1) | ./script/log_highlight.sh

build/post_opt.dcp: script/opt.tcl build/post_synth.dcp
	(cd build/ && $(VIVADO) -mode batch -source ../$< 2>&1) | ./script/log_highlight.sh

build/post_place.dcp: script/place.tcl build/post_opt.dcp
	(cd build/ && $(VIVADO) -mode batch -source ../$< 2>&1) | ./script/log_highlight.sh

build/post_route.dcp: script/route.tcl build/post_place.dcp
	(cd build/ && $(VIVADO) -mode batch -source ../$< 2>&1) | ./script/log_highlight.sh

build/output.bit: script/bitstream.tcl build/post_route.dcp
	(cd build/ && $(VIVADO) -mode batch -source ../$< 2>&1) | ./script/log_highlight.sh

clean:
	rm -rf build/

.PHONY: program clean
