# UPduino V3.0 template

This repo is intended to be a starting point for SystemVerilog projects targeting the UPduino V3.0. It is intentionally opinionated, and may require modification to suit others' use-cases. In short, this project is designed for:
- Easy set-up (most dependencies are installed via apio)
- SystemVerilog support via [sv2v](https://github.com/zachjs/sv2v)
- Multiple separate top-level testbenches

While it uses apio, many of the Make rules are customized to invoke iverilog/verilator/gtkwave directly.

## Development environment

The Makefile requires GNU Make, so Linux is the expected host environment. I use Ubuntu 20.04.

On Windows, you can install VMware (I use VMware Workstation, although Fusion would probably also work) and run a Linux virtual machine within it. Once the virtual machine is running, if you plug in the UPduino, VMware will prompt you to choose what it does with the device; select the option to connect it to your VM. You can tell it to remember this choice for the future.

All future commands will assume a Linux environment.

### System setup

The following steps are specific to Ubuntu. Similar steps will work for other Linux distributions.

First, install Python, apio, dependencies and necessary tools:

```bash
# Python and pip
sudo apt install -y python3-pip git

# gtkwave
sudo apt install -y gtkwave screen

# apio
pip3 install --user apio

echo 'export PATH="$PATH:${HOME}/.local/bin"' >> ~/.bashrc
export PATH="$PATH:${HOME}/.local/bin"

# apio packages
apio install system scons yosys ice40 iverilog verilator
```

Install sv2v (the below will put it in `~/.bin/`, but feel free to choose a different location):

```bash
# sv2v
mkdir ~/.bin/ && cd ~/.bin/
wget https://github.com/zachjs/sv2v/releases/download/v0.0.6/sv2v-Linux.zip
unzip sv2v-Linux.zip

echo 'export PATH="$PATH:${HOME}/.bin/sv2v-Linux"' >> ~/.bashrc
```

Add your user account to the necessary groups for accessing the serial port:

```
sudo usermod -aG tty $USER
sudo usermod -aG dialout $USER
```

Create an appropriate udev rule for the USB device. Here's a one-liner command to do this:

```bash
echo "ATTRS{idVendor}==\"0403\", ATTRS{idProduct}==\"6014\", MODE=\"0660\", GROUP=\"plugdev\", TAG+=\"uaccess\"" | sudo tee /etc/udev/rules.d/53-lattice-ftdi.rules
```

Reload the udev rules so the new one is picked up without reboot:

```bash
sudo udevadm control --reload-rules && sudo udevadm trigger
```

## Getting started

1. Clone this repo (or your fork of it) locally.
2. `cd` into the directory.
3. Run `make` and confirm no errors are printed.
4. Run `make sim-serial_transmitter`. It should open gtkwave with the simulation output from the `serial_transmitter`'s testbench. Try dragging in some signals from the left pane!
5. Ensure your UPduino is connected and run `make upload`. It should synthesize for and flash the device. You should now see the green and blue LEDs blinking.
6. Unplug and re-plug the UPduino.
7. Temporarily make a connection between pin 2 and GND on the UPduino. (Make sure not to short any other pins!) This is the default reset pin I've configured. While this connection is held, the red LED should be on.
8. On your PC, run `screen /dev/ttyUSB0 9600`. You should see "Hello world!" printed repetitively.
9. Exit `screen` by pressing <kbd>Ctrl</kbd>+<kbd>A</kbd> then <kbd>\\</kbd> and confirming the prompt with <kbd>y</kbd>.

## What's included

Files of interest in this repo:
- The Makefile automates stitching together `sv2v` and the various `apio` tools.
- `top.sv` is the top-level module. Currently, there's a serial transmission demo and some LED blinking logic. Feel free to change these as desired.
- `serial_transmitter.sv` is a very simple UART module for sending text back to the host PC. It accepts one byte at a time.
- `serial_transmitter_tb.sv` is a testbench for the above.
- `upduino.pcf` specifies the pin mappings on the UPduino. It is the stock UPduino PCF file from the original sample repo, but with a pull-up resistor enabled on GPIO pin 2 to use as a reset pin.

## General workflow

- Develop in `.sv` files.
- Verify and lint with `make`.
- Write testbenches in files with names ending in `_tb.sv` (see below). Iterate on the design in simulation.
- When ready, `make upload` will upload to the board.
- Test your design with output from serial (UART) or the LEDs.
  - As mentioned above, you can monitor serial output with `screen /dev/ttyUSB0 9600`.

## Notes and catches

**Workflow:**
- The Makefile transpiles your SystemVerilog code into plain Verilog. Everything but the testbenches is automatically combined into a file called `all.v`. This file should be ignored and will be automatically re-generated; don't edit it.
- Testbenches are each transpiled into their own file, of the same name as the original, but with the `.v` extension. The same as above applies.
- Errors from most tasks will be attributed to `all.v` rather than your source `.sv` files. When you get an error, check the relevant line in `all.v`; it should be clear where it corresponds to in the original SystemVerilog.
- Testbenches aren't validated by `make lint`, `make verify` or `make build`. You'll have to watch for error output or misbehavior in your testbenches while simulating.

**Testing in hardware:**
- The "reset" signal is, as configured in the provided code, GPIO pin 2. "resetting" means connecting pin 2 to GND temporarily.
- If your current code uses the serial line, it may cause intermittent errors while uploading to the board (`make upload`). If it fails or freezes, cancel and re-try. It'll work after a few times.
- After uploading code, if you want the serial output to work (e.g. via the `screen` command) you will need to unplug and re-plug the board via USB (and remember to reset it!).

## `make` targets

- `make verify`: run your code through Icarus Verilog compiler.
- `make lint`: lint your code with `verilator`.
- `make build`: synthesize your code for the UPduino.
- `make sim-MODNAME`: simulate the testbench called `MODNAME_tb.sv` and open the results in `gtkwave`.
- `make upload`: synthesize and upload to a real board.

## Testbenches

Testbenches are authored in files ending with `_tb.sv`. I recommend you name them with the same prefix as the module you're testing. For example, the testbench for `serial_transmitter.sv` is named `serial_transmitter_tb.sv` and can be run with `make sim-serial_transmitter`.

When creating a new testbench, it is probably easiest to copy the given one for `serial_transmitter`. Note that every testbench should have a block like the following at the top of the module, with names changed appropriately:

```verilog
initial begin
    $dumpfile("modname.vcd");
    $dumpvars(0,modname_tb);
end
```
