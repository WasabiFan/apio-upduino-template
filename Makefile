SOURCE_SV_FILES := $(filter-out $(wildcard ./*_tb.sv), $(wildcard ./*.sv))

YOSYS_ROOT = $(shell dirname $(shell dirname $(shell apio raw "which yosys")))
IVERILOG_ROOT = $(shell dirname $(shell dirname $(shell apio raw "which iverilog")))
CELLS_SIM_PATH = $(join $(YOSYS_ROOT),/share/yosys/ice40/cells_sim.v)

all: all.v verify lint build

# For some features, such as packages, sv2v requires being able to process all
# sources at once and output a single Verilog file. So we have it combine them
# into "all.v".
all.v: $(SOURCE_SV_FILES)
	sv2v $^ > $@

verify: all.v
	apio verify

# "apio lint" lints all.v, but it's preferrable if the linter is operating
# on our original SV source instead.
# Note: verilator does not work with non-synthesizable language features,
# so testbenches aren't linted.
lint:
	apio raw "verilator --lint-only -v $(CELLS_SIM_PATH) $(SOURCE_SV_FILES)"

build: all.v
	apio build

upload: all.v
	apio upload

%_tb.v: %_tb.sv
	sv2v $^ > $@

# Apio only supports one testbench (it adds all *_tb.v files at once); the below
# is an expansion of their original rules, with support for multiple testbenches.
%_tb.out: all.v %_tb.v
	apio raw "iverilog -B \"$(IVERILOG_ROOT)/lib/ivl\" -o $@ -D VCD_OUTPUT=$(basename $@) $(CELLS_SIM_PATH) $^"

%_tb.vcd: %_tb.out
	apio raw "vvp -M \"$(IVERILOG_ROOT)/lib/ivl\" $<"

# testbenches should be SystemVerilog ending in "_tb.v". For some file
# "mymodule_tb.sv", simulate with "make sim-mymodule".
sim-%: %_tb.vcd
	apio raw "gtkwave $< $(patsubst %.vcd, %.gtkw, $<)"

clean:
	apio clean
	rm -f all.v *_tb.vcd *_tb.out *_tb.v
