# *Deep:* Dark-Fantasy

> Global Dark mode for **ALL apps** on **ANY platforms**.

:arrow_down: See the demo below :arrow_down:

![Demonstration of the Deep: Dark-Fantasy system.](demo.gif)

:arrow_up: See the demo above :arrow_up:

## How?

By putting an FPGA between your video card and monitor.

## Prerequisite

- You need a video card and a monitor that supports HDMI.
- You need an FPGA develop board. We only officially support [Digilent Zybo Z7-20](https://store.digilentinc.com/zybo-z7-zynq-7000-arm-fpga-soc-development-board/).
- You need an SD card with at least 8MiB of free space.

## TL;DR

You can follow these steps get *Deep:* Dark-Fantasy running:

1. Get a [Zybo Z7-20](https://store.digilentinc.com/zybo-z7-zynq-7000-arm-fpga-soc-development-board/) if you don't have one.
1. Get an SD card, format its first partition as FAT32.
1. Download our pre-built boot image file (`BOOT.bin`) from [here](https://github.com/b1f6c1c4/Deep-DarkFantasy/releases/latest/).
1. Put the downloaded image file (`BOOT.bin`) into the SD card. Do *NOT* modify its name.
1. Use a power adapter to supply the FPGA develop board.
1. Use an HDMI Cable connect your video source (video card / mother board video output) to the HDMI *RX* port of the board.
1. Use another HDMI Cable connect your video destination (monitor) to the HDMI *TX* port of the board.
1. Power on the board.
1. There are four switches on the board. The best settings for *Deep:* Dark-Fantasy should be **all switches turned off** (away form the LEDs means off).

    | PCB Symbol | SW3 | SW2 | SW1 | SW0 |
    | ---------- | ---- | ---- | ---- | ---- |
    | Function | Freeze Image | Disable Buffering | Plain Invert | Plain Original |
    | Description | Turn off buffer refresh, so the image is frozen. | Turn off frame buffering, will reduce the latency but may incur flashing image. | Invert every pixels, not just bright ones. | Don't invert any pixels, even if bright ones. |

## Build *Deep:* Dark-Fantasy from source code

**If the default settings don't work for you for some reason, you should try build the project from source code.**

Note: You need Xilinx Vivado (2018.2), `make`, `bash`, and `awk` to generate the bitstream file. Futhermore, you need Xilinx SDK (2018.2), `make`, `bash` to generate the bootable image.

### Step 1: Get the source code

You need to (fork and) clone the repo first:
```bash
git clone --depth=1 https://github.com/b1f6c1c4/Deep-DarkFantasy.git
git submodule update --init --recursive
# Or, use git-get:
# git gets b1f6c1c4/Deep-DarkFantasy
```

In the file `config` you can find the following parameters:
```verilog
# Video parameters
H_WIDTH=1920
H_START=2008
H_TOTAL=2200
V_HEIGHT=1080
FREQ=148.50

# Dark-Fantasy parameters
KH=30
KV=30
```

### Step 2: Configure the video parameters

Since most OS and video cards will adapt to whatever device connected to it,
you usually don't need to modify these parameters.
However, if it is NOT the case, you must either force your video card to cater to the FPGA,
or force your FPGA to cater to the video card.
The first way is usually easier, but here are are explaining the second way.

- If you are using Linux with X11, use the following command:

    ```bash
    xrandr --verbose
    ```
    And you will see tons of modelines.
    Find the one with ` *current`, which looks like:
    ```
    1920x1080 (0x1c8) 148.500MHz +HSync +VSync *current +preferred
          h: width  1920 start 2008 end 2052 total 2200 skew    0 clock  67.50KHz
          v: height 1080 start 1084 end 1089 total 1125           clock  60.00Hz
    ```
    Now you should know where does those magic numbers came from.
    Edit the parameters in `design/top.v` and `constr/ax7z100.xdc` to match the numbers from `xrandr`.

    Note: If you have multiple displays, pick the one you want to use *Deep:* Dark-Fantasy.
    You need one FPGA develop board *per display* if you want all your displays to be Dark-Fantasy.

- If you are using macOS or Windows, you are having some trouble.
    If you do encounter problems like this, please feel free to submit an [issue](https://github.com/b1f6c1c4/Deep-DarkFantasy/issues).

### Step 3: Configure the block size

You can modify the two parameter `KH` and `KV`.
It is used to specify the size of blocks - the smaller blocks are, the finer granularity Dark-Fantasy effect is achieved.
However, if the blocks are too small, texts will become illegible for read.
Furthermore, *Deep:* Dark-Fantasy may not work as desired with very small (<5) `KH` and/or `KV`.

### Step 4: Build the project

The project takes a while to build - usually several minutes to half an hour.
Multicore won't help.
```bash
# Specify your Xilinx Vivado installation
# Specify your Xilinx SDK installation
export VIVODO=/opt/xilinx/Vivado/2018.2
export SDK=/opt/xilinx/SDK/2018.2
# Perform synthsizing, implementation, bitstream creation, boot image creation.
# This may take a while (15~25min), so be patient
make -j8
```

You should be able to find `BOOT.bin` in the `build` folder.

