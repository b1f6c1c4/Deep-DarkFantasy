VIVADO?=/opt/xilinx/Vivado/2018.2
SDK?=/opt/xilinx/SDK/2018.2
BOOTGEN?=bootgen
DESIGN=$(wildcard design/*.v)
CONSTR=$(wildcard constr/*.xdc)
XCI=$(patsubst ip/%.xci,%,$(wildcard ip/*.xci))
FONT?=/usr/share/fonts/TTF/Consolas-Regular.ttf

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
export SMOOTH_T
export FONT_SZ

image: build/BOOT.bin

build: build/output.bit

program: script/program.tcl script/common.tcl build/output.bit
	./script/launch.sh $<

build/post_synth.dcp: script/synth.tcl script/common.tcl $(DESIGN) constr/timing.xdc config
	./script/launch.sh $< $(XCI)

define IP_TEMPLATE

build/ip/$1/$1.dcp: script/synth_ip.tcl ip/$1.xci script/common.tcl
	./script/launch.sh $$^

build/post_synth.dcp: build/ip/$1/$1.dcp

endef

$(foreach x,$(XCI),$(eval $(call IP_TEMPLATE,$(x))))

vivado-library/dvi2rgb/src/dgl_1080p_cea.data: design/edid.txt
	mkdir -p build/
	awk '{ if (a) { sub(/ \|/,":"); print; } } /--/ { a = 1; }' $< \
		| xxd -r | xxd -b -c 1 | awk '{ print $$2; }' >$@

build/ip/dvi2rgb_1080p/dvi2rgb_1080p.dcp: vivado-library/dvi2rgb/src/dgl_1080p_cea.data

build/post_opt.dcp: script/opt.tcl script/common.tcl build/post_synth.dcp constr/debug.xdc
	./script/launch.sh $<

build/post_place.dcp: script/place.tcl script/common.tcl build/post_opt.dcp constr/zybo-z7-20.xdc
	./script/launch.sh $<

build/output.bit: script/route.tcl script/common.tcl build/post_place.dcp
	./script/launch.sh $<

build/system.hdf: script/fsbl.tcl
	./script/launch.sh $<

build/fsbl/fsbl.sdk/fsbl/Release/fsbl.elf: script/fsbl-sdk.tcl build/system.hdf
	./script/launch-sdk.sh $<

build/BOOT.bin: script/fsbl.bif build/fsbl/fsbl.sdk/fsbl/Release/fsbl.elf build/output.bit
	$(SDK)/bin/bootgen -arch zynq -image $< -w -o build/BOOT.bin

build/overlay/node_modules: script/overlay/package.json script/overlay/package-lock.json
	mkdir -p build/overlay/
	cp -f $^ build/overlay/
	cd build/overlay/ && npm ci

build/overlay/font_info.json: build/overlay/node_modules config
	./build/overlay/node_modules/lv_font_conv/lv_font_conv.js --font $(FONT) -r 0x30-0x37 --size $(FONT_SZ) --format dump --bpp 1 -o build/overlay/

build/overlay/overlay.js: script/overlay/overlay.js
	mkdir -p build/overlay/
	cp $< $@

build/overlay/rom.bin: build/overlay/overlay.js build/overlay/font_info.json
	node $^ >$@

build/BOOT.bin: build/overlay/rom.bin

constr/debug.xdc:
	touch $@

clean:
	rm -rf build/

.PHONY: image build program clean
