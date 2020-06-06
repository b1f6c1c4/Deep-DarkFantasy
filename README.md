# Deep: Dark-Fantasy

> Dark mode for **ALL apps** on **ANY platform**.

## Prerequisite

- You need an FPGA develop board with (at least) one HDMI input, one HDMI output, four buttons and four LEDs.
    - We officially support Alinx AX7Z100, which has a powerful Xilinx Zynq-7000 ARM Kintex-7 FPGA SoC on it.
    It's also equpped with an SIL9013 HDMI video input ASIC chip and an ADV7511 HDMI video output ASIC chip.
- You need some software (with proper licenses, if needed) to synthesize Deep: Dark-Fantasy to your FPGA.
    - We officially support Xilinx Vivado, version 2019.2.
- You need `make`, `bash`, and `awk`.
- We do provide pre-built bitstream, but only for some [modelines](#Configure-video-parameters).

## Usage

You need to (fork and) clone the repo first:
```bash
git clone --depth=1 https://github.com/b1f6c1c4/Deep-DarkFantasy.git
```

At the very beginning of `design/top.v` you can find the following parameters:
```verilog
   parameter H_WIDTH  = 1920,
   parameter H_START  = 2008,
   parameter H_TOTAL  = 2200,
   parameter V_HEIGHT = 1080,
   parameter KH = 30,
   parameter KV = 30
```
And at the very beginning of `constr/ax7z100.xdc` you can find the following parameters:
```
set VIN_FREQ 148.500 # MHz
```

### Configure video parameters

You are **required** to modify these values to match your display settings for Deep: Dark-Fantasy to work properly.
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

    Note: If you have multiple displays, pick the one you want to use Deep: Dark-Fantasy.
    You need one FPGA develop board *per display* if you want all your displays to be Dark-Fantasy.

- If you are using macOS, TODO
- If you are using Windows, TODO

### Configure block size

In `design/top.v`, you can modify the two parameter `KH` and `KV`.
It is used to specify the size of blocks - the smaller blocks are, the finer granularity Dark-Fantasy effect is achieved.
However, if the blocks are too small, texts will become illegible for read.
Furthermore, since the circuit area scales at `O(W_TOTAL*KV+W_TOTAL/KH)`,
a configuration with large `KV` or very small `KH` may be too big for your FPGA.
In that case you have to reduce `KV`, increase `KH`.
Alternatively, you can reduce display resolution and reduce `W_TOTAL` correspondingly.

### Build the project

The project takes a while to build, from several minutes to half an hour.
```bash
# Specify your vivado installation
VIVODO=/opt/Xilinix/Vivado/2019.2/bin/vivado
# Perform synthsizing, implementation, and bitstream creation.
# This may take a while, so wait with patience
make bs
```

## Connect your FPGA board to your computer and display

Make sure you have connected your FPGA to your computer with JTAG.
Program the device by calling:
```bash
make program
```
