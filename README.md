# *Deep:* Dark-Fantasy

> Global Dark mode for **ALL apps** on **ANY platforms**.

## Prerequisite

- You need an FPGA develop board with (at least) one HDMI input, one HDMI output, four buttons and four LEDs.
    - We officially support Alinx AX7Z100, which has a powerful Xilinx Zynq-7000 ARM Kintex-7 FPGA SoC on it.
    It's also equpped with an SIL9013 HDMI video input ASIC chip and an ADV7511 HDMI video output ASIC chip.
- You need some software (with proper licenses, if needed) to synthesize *Deep:* Dark-Fantasy to your FPGA.
    - We officially support Xilinx Vivado, version 2019.2.
- You need `make`, `bash`, and `awk`.
- We do provide pre-built bitstream, but only for the default [config](#Step-2-Configure-video-parameters).

## Installation

### Step 1: Get the source code

You need to (fork and) clone the repo first:
```bash
git clone --depth=1 https://github.com/b1f6c1c4/Deep-DarkFantasy.git
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

### Step 2: Configure video parameters

You are **required** to modify these values to match your display settings for *Deep:* Dark-Fantasy to work properly.

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

- If you are using macOS, TODO

- If you are using Windows, TODO

### Step 3: Configure block size

You can modify the two parameter `KH` and `KV`.
It is used to specify the size of blocks - the smaller blocks are, the finer granularity Dark-Fantasy effect is achieved.
However, if the blocks are too small, texts will become illegible for read.
Furthermore, since the circuit area scales at `O(H_TOTAL*KV+H_TOTAL/KH)`,
a configuration with large `KV` or very small `KH` may be too big for your FPGA.
In that case you have to reduce `KV`, increase `KH`.
Alternatively, you can reduce display resolution and reduce `H_TOTAL` correspondingly.

### Step 4: Build the project

If you find that the default config looks good to you, you can download the pre-built [bitstream file](https://github.com/b1f6c1c4/Deep-Dark-Fantasy/releases/download/latest/output.bit) and put it in the `build` directory:
```bash
mkdir -p build/
wget -o build/ https://github.com/b1f6c1c4/Deep-Dark-Fantasy/releases/download/latest/output.bit
ls build/output.bit
```
And jump to the [next step](#Step-4-Setup-your-physical-settings-and-program-your-device).

If the default config doesn't work for you, you need to build it yourself.
The project takes a while to build - usually several minutes to half an hour.
Multicore won't help.
```bash
# Specify your vivado installation
VIVODO=/opt/Xilinix/Vivado/2019.2/bin/vivado
# Perform synthsizing, implementation, and bitstream creation.
# This may take a while, so be patient
make
```

### Step 4: Setup your (physical) settings and program your device

1. Using a power adapter to supply the FPGA develop board.
1. Using a JTAG debugger, connect FPGA develop board to your develop computer (where vivado exists).
1. Using an HDMI Cable, connect your video source (video card / mother board video output) to the HDMI *IN* port of the board.
1. Using another HDMI Cable, connect your video destination (monitor) to the HDMI *OUT* port of the board.
1. Power on the board.
1. Program the device by calling:

    ```bash
    make program
    ```

1. The fan should stop and then start again. When it starts, you should expect to see your Dark-Fantasy desktop on your monitor!

## Use the *Deep:* Dark-Fantasy

**Note: We assume that you are using the Alinx AX7Z100 development board.**

There are four LEDS on the board:

| PCB Symbol | LED1 | LED2 | LED3 | LED4 |
| ---------- | ---- | ---- | ---- | ---- |
| Default | On | Off | Off | Off |
| Indication | Block-based Fantasy | Line-based Fantasy | Frame-based Fantasy | Light-Fantasy |
| Description | Pixels are grouped into `KH`-by-`KV` blocks. | Effectively set `KH` to infinity. | Effectively set `KH` and `KV` both to infinity. | Invert each pixel, becoming light mode. |

There are five buttons on the board:

| PCB Symbol | RESET | KEY1 | KEY2 | KEY3 | KEY4 |
| ---------- | ----- | ---- | ---- | ---- | ---- |
| Function | System Reset | Fantasy Reset | Switch Fantasy | Invert Fantasy | No Fantasy |
| Press or Hold | Press | Press | Press | Press | Hold Down |
| Description | Remove the program from the device. | Switch to the default mode (Block-based Dark-Fantasy). | Switch between Block-based, Line-based, Frame-based, and Non-Fantasy mode. | Switch between Dark-Fantasy and Light-Fantasy. | When held down, temporarily show the original image. |

## Limitation

- It does not fully support `-Hsync` nor `-Vsync`.
- For large `KH` and small `KV`, it consumes too much FPGA resource.
- You need to re-program the device every time after a power cycle.

