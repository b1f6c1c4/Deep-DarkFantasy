# *Deep:* Dark-Fantasy

> Global Dark mode for **ALL apps** on **ANY platforms**.

:arrow_down: See the demo below :arrow_down:

![Demonstration of the Deep: Dark-Fantasy system.](demo.gif)

:arrow_up: See the demo above :arrow_up:

## How?

By putting an FPGA between your video card and monitor.

## Prerequisite

- You need a video card and a monitor that supports HDMI.
- You need an FPGA develop board. For v2.0 we only support [Digilent Zybo Z7-20](https://store.digilentinc.com/zybo-z7-zynq-7000-arm-fpga-soc-development-board/).
- You need a microSD card with at least 8MiB of free space.

Note: For [v1.0](https://github.com/b1f6c1c4/Deep-DarkFantasy/tree/v1.0)
we supported [AX7Z100](http://www.alinx.com.cn/index.php/default/content/124.html)
but that was discontinued.

## TL;DR

You can follow these steps get *Deep:* Dark-Fantasy running:

1. Get a [Zybo Z7-20](https://store.digilentinc.com/zybo-z7-zynq-7000-arm-fpga-soc-development-board/) if you don't have one.
1. Get a microSD card, format its first partition as FAT32.
1. Download our pre-built boot image file (`BOOT.bin`) from [here](https://github.com/b1f6c1c4/Deep-DarkFantasy/releases/latest/).
1. Put the downloaded image file (`BOOT.bin`) into the microSD card. Do *NOT* modify its name.
1. Put the microSD card into the `SD MICRO` slot on the FPGA develop board.
1. On the Zybo Z7-20 board, locate jumper `J4` and set it to `SD`. See "microSD Boot Mode" in the [Reference Manual](https://reference.digilentinc.com/_media/reference/programmable-logic/zybo-z7/zybo-z7_rm.pdf) (page 13) for help.
1. Use a power adapter to supply the FPGA develop board.
1. Locate jumper `JP6` and set it to `WALL`. See "Power Supplies" in the [Reference Manual](https://reference.digilentinc.com/_media/reference/programmable-logic/zybo-z7/zybo-z7_rm.pdf) (page 9) for help.
1. Use an HDMI Cable connect your video source (video card / mother board video output) to the HDMI *RX* port of the board.
1. Use another HDMI Cable connect your video destination (monitor) to the HDMI *TX* port of the board.
1. Power on the board.
1. Make sure that all four switches are *off* (away from the LEDs.)
1. There are four LEDs. LED2~LED0 are used to indicate which Fantasy mode the devices is currently in. There are 8 Fantasy modes in total, so the LEDs are organized in binary form.

    | PCB Symbol | LED3 | LED2 | LED1 | LED0 |
    | ---------- | ---- | ---- | ---- | ---- |
    | Function | Video In | Fantasy Mode (MSB) | Fantasy Mode | Fantasy Mode (LSB) |

1. There are four contiguous black buttons on the board, which can be used to configure *Deep:* Dark-Fantasy to work in one of the 8 Fantasy modes. Try'em all and find the one that fits you best.

    | PCB Symbol | BTN3 | BTN2 | BTN1 | BTN0 |
    | ---------- | ---- | ---- | ---- | ---- |
    | Function | Reset | Previous Fantasy | Next Fantasy | Use Default Fantasy (3) |

## Build *Deep:* Dark-Fantasy from source code

**If the default settings don't work for you for some reason, you should try build the project from source code.**

Note: You need Xilinx Vivado (2018.2), `make`, `bash`, `node`, `npm`, and `awk` to generate the bitstream file.
You also need a ttf font for the overlay number display.
Futhermore, you need Xilinx SDK (2018.2), `make`, `bash` to generate the bootable image.

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
KH=24 # Block width (px)
KV=24 # Block height (px)
SMOOTH_T=1200 # Smoothing time (ms)

# Overlay parameters
FONT_SZ=768 # (px)
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
    Edit the parameters in `config` to match the numbers from `xrandr`.

    Note: If you have multiple displays, pick the one you want to use *Deep:* Dark-Fantasy.
    You need one FPGA develop board *per display* if you want all your displays to be Dark-Fantasy.

- If you are using macOS or Windows, you are having some trouble.
    If you do encounter problems like this, please feel free to submit an [issue](https://github.com/b1f6c1c4/Deep-DarkFantasy/issues).

### Step 3: Configure the block size

You can modify the two parameter `KH` and `KV`.
It is used to specify the size of blocks - the smaller blocks are, the finer granularity Dark-Fantasy effect is achieved.
However, if the blocks are too small, texts will become illegible for read.
Furthermore, *Deep:* Dark-Fantasy may not work as desired with very small (<5) `KH` and/or `KV`.

### Step 4: Configure the other parameters

- `SMOOTH_T` specifies the overall time of smooth transition (in milliseconds).
- `FONT_SZ` specifies the size of overlay mode font (in pixels). If set too large, you will run out of BRAM, so be discreet.

### Step 5: Build the project

The project takes a while to build - usually several minutes to half an hour.
Multicore won't help.
```bash
# Specify the font
export FONT=/usr/share/fonts/truetype/noto/NotoMono-Regular.ttf
# Specify your Xilinx Vivado installation
# Specify your Xilinx SDK installation
export VIVODO=/opt/xilinx/Vivado/2018.2
export SDK=/opt/xilinx/SDK/2018.2
# Perform synthsizing, implementation, bitstream creation, boot image creation.
# This may take a while (15~25min), so be patient
make -j8
```

You should be able to find `BOOT.bin` in the `build` folder.
Put it into a FAT32-formatted SD card and put it on your FPGA board.
Don't forget to configure the boot mode.

## Limitation

- 4K is not supported. 1080p 120Hz is not supported.
- Only one resolution and refresh rate is supported once synthesized.

