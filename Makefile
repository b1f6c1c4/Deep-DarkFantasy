VIVADO?=/opt/xilinx/Vivado/2018.2
SDK?=/opt/xilinx/SDK/2018.2
BOOTGEN?=bootgen
DESIGN=$(wildcard design/*.v)
CONSTR=$(wildcard constr/*.xdc)
XCI=$(patsubst ip/%.xci,%,$(wildcard ip/*.xci))

PART=xc7z020clg400-1
export PART

include config
export H_WIDTH
export H_START
export H_TOTAL
export V_HEIGHT
export FREQ
export KH
export KV
export SMOOTH_W
export SMOOTH_T

image: build/BOOT.bin

build: build/output.bit

program: script/program.tcl build/output.bit
	./script/launch.sh $<

define IP_TEMPLATE

build/ip/$1/$1.dcp: script/synth_ip.tcl ip/$1.xci
	./script/launch.sh $$^

build/post_synth.dcp: build/ip/$1/$1.dcp

endef

$(foreach x,$(XCI),$(eval $(call IP_TEMPLATE,$(x))))

vivado-library/dvi2rgb/src/dgl_1080p_cea.data: design/edid.txt
	mkdir -p build/
	awk '{ if (a) { sub(/ \|/,":"); print; } } /--/ { a = 1; }' $< \
		| xxd -r | xxd -b -c 1 | awk '{ print $$2; }' >$@

build/ip/dvi2rgb_1080p/dvi2rgb_1080p.dcp: vivado-library/dvi2rgb/src/dgl_1080p_cea.data

build/post_synth.dcp: script/synth.tcl $(DESIGN) $(CONSTR) config
	./script/launch.sh $< $(XCI)

build/post_opt.dcp: script/opt.tcl build/post_synth.dcp
	./script/launch.sh $<

build/post_place.dcp: script/place.tcl build/post_opt.dcp
	./script/launch.sh $<

build/post_route.dcp: script/route.tcl build/post_place.dcp
	./script/launch.sh $<

build/output.bit: script/bitstream.tcl build/post_route.dcp
	./script/launch.sh $<

build/system.hdf: script/fsbl.tcl
	./script/launch.sh $<

build/fsbl/fsbl.sdk/fsbl/Release/fsbl.elf: script/fsbl-sdk.tcl build/system.hdf
	./script/launch-sdk.sh $<

build/BOOT.bin: script/fsbl.bif build/fsbl/fsbl.sdk/fsbl/Release/fsbl.elf build/output.bit
	$(SDK)/bin/bootgen -arch zynq -image $< -w -o build/BOOT.bin

clean:
	rm -rf build/

.PHONY: image build program clean
