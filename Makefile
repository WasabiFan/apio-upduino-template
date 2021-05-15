SOURCE_SV_FILES := $(filter-out $(wildcard ./*_tb.sv), $(wildcard ./*.sv))

YOSYS_ROOT = $(shell dirname $(shell dirname $(shell apio raw "which yosys")))
IVERILOG_ROOT = $(shell dirname $(shell dirname $(shell apio raw "which iverilog")))
CELLS_SIM_PATH = $(join $(YOSYS_ROOT),/share/yosys/ice40/cells_sim.v)

# Extra options passed to the synth_ice40 yosys command.
# "-retime -relut -abc2" gives small but significant improvements in LUT utilization and timing.
SYNTH_ADDITIONAL_OPTIMIZATIONS = -retime -relut -abc2
# Base clock frequency to assume for timing analysis.
# icestorm pnr doesn't seem to understand the clock divider param on the oscillator primitive.
PNR_BASE_FREQUENCY = 48

# Any SystemVerilog files that should be compiled into each testbench's individual Verilog blob.
# Unnecessary unless your testbenches themselves depend on SystemVerilog (not plain Verilog)
# features of other files.
TESTBENCH_SV_DEPS =

# Files included via $readmemh or similar, which aren't code but should nonetheless trigger
# re-synthesis if changed.
ALL_BRAM_INIT_FILES =

# Preprocessor definitions which are specified only in simulation (not for fpga synthesis)
SIM_PREPROCESSOR_DEFINES = -D SIMULATION

.PHONY: all
all: all.v verify lint build

# For some features, such as packages, sv2v requires being able to process all
# sources at once and output a single Verilog file. So we have it combine them
# into "all.v".
all.v: $(SOURCE_SV_FILES)
	sv2v $^ > $@

all_sim.v: $(SOURCE_SV_FILES)
	sv2v $^ $(SIM_PREPROCESSOR_DEFINES) > $@

.PHONY: verify
verify: all.v
	apio raw "iverilog -B \"$(IVERILOG_ROOT)/lib/ivl\" -o hardware.out -D VCD_OUTPUT= $(CELLS_SIM_PATH) all.v"

# "apio lint" lints all.v, but it's preferrable if the linter is operating
# on our original SV source instead.
# Note: verilator does not work with non-synthesizable language features,
# so testbenches aren't linted.
.PHONY: lint
lint:
	apio raw "verilator --lint-only --top-module top -v $(CELLS_SIM_PATH) $(SOURCE_SV_FILES)"

.PHONY: build
build: hardware.bin

hardware.json: $(ALL_BRAM_INIT_FILES) all.v
	apio raw "yosys -p \"synth_ice40 $(SYNTH_ADDITIONAL_OPTIMIZATIONS) -json hardware.json\" -q all.v"

hardware.asc: $(ALL_BRAM_INIT_FILES) hardware.json upduino.pcf
	apio raw "nextpnr-ice40 --freq $(PNR_BASE_FREQUENCY) --up5k --package sg48 --json hardware.json --asc hardware.asc --pcf upduino.pcf -q"

hardware.bin: hardware.asc
	apio raw "icepack hardware.asc hardware.bin"

# Phony target which performs the end-to-end synthesis with full debug output
build-verbose: $(ALL_BRAM_INIT_FILES) all.v
	apio raw "yosys -p \"synth_ice40 $(SYNTH_ADDITIONAL_OPTIMIZATIONS) -json hardware.json\" all.v"
	apio raw "nextpnr-ice40 --freq $(PNR_BASE_FREQUENCY) --up5k --package sg48 --json hardware.json --asc hardware.asc --pcf upduino.pcf"
	apio raw "icepack hardware.asc hardware.bin"

.PHONY: upload
upload: hardware.bin
	apio raw "iceprog -d i:0x0403:0x6014:0 hardware.bin"

%_tb.v: $(TESTBENCH_SV_DEPS) %_tb.sv
	sv2v $^ > $@

# Apio only supports one testbench (it adds all *_tb.v files at once); the below
# is an expansion of their original rules, with support for multiple testbenches.
%_tb.out: all_sim.v %_tb.v
	apio raw "iverilog -B \"$(IVERILOG_ROOT)/lib/ivl\" -o $@ -D VCD_OUTPUT=$(basename $@) $(SIM_PREPROCESSOR_DEFINES) $(CELLS_SIM_PATH) $^"

%_tb.vcd: %_tb.out
	apio raw "vvp -M \"$(IVERILOG_ROOT)/lib/ivl\" $<"

# testbenches should be SystemVerilog files ending in "_tb.sv". For some file
# "mymodule_tb.sv", simulate with "make sim-mymodule".
sim-%: %_tb.vcd
	apio raw "gtkwave $< $(patsubst %.vcd, %.gtkw, $<)"

clean:
	apio clean
	rm -f all.v all_sim.v *_tb.vcd *_tb.out *_tb.v
