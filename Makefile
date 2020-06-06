VIVADO?=vivado
DESIGN=$(wildcard design/*.v)
CONSTR=$(wildcard constr/*.xdc)
XCI=$(wildcard ip/*.xci)

include config

build: build/output.bit

program: script/program.tcl build/output.bit
	./script/launch.sh $<

build/post_synth.dcp: script/synth.tcl $(DESIGN) $(CONSTR) $(XCI) config
	./script/launch.sh $<

build/post_opt.dcp: script/opt.tcl build/post_synth.dcp
	./script/launch.sh $<

build/post_place.dcp: script/place.tcl build/post_opt.dcp
	./script/launch.sh $<

build/post_route.dcp: script/route.tcl build/post_place.dcp
	./script/launch.sh $<

build/output.bit: script/bitstream.tcl build/post_route.dcp
	./script/launch.sh $<

clean:
	rm -rf build/

.PHONY: program build clean
