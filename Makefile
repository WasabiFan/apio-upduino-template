SOURCE_SV_FILES := $(wildcard ./*.sv)

all: all.v verify lint build

# For some features, such as packages, sv2v requires being able to process all
# sources at once and output a single Verilog file. So we have it combine them
# into "all.v".
all.v: $(SOURCE_SV_FILES)
	CONTENTS=$$(sv2v $^) && echo "$$CONTENTS" > $@

verify: all.v
	apio verify

# "apio lint" lints all.v, but it's preferrable if the linter is operating
# on our original SV source instead.
# Note: verilator does not work with non-synthesizable language features,
# so testbenches aren't linted.
lint:
	YOSYS_ROOT="$$(dirname $$(dirname $$(apio raw "which yosys")))" && apio raw "verilator --lint-only -v $$YOSYS_ROOT/share/yosys/ice40/cells_sim.v $(SOURCE_SV_FILES)"

build: all.v
	apio build

upload: all.v
	apio upload

sim: all.v
	apio sim

clean:
	apio clean
	rm all.v
