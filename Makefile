SV_FILES := $(wildcard ./*.sv)

all: all.v

# For some features, such as packages, sv2v requires being able to process all
# sources at once and output a single Verilog file. So we have it combine them
# into "all.v".
all.v: $(SV_FILES)
	CONTENTS=$$(sv2v $^) && echo "$$CONTENTS" > $@

verify: all.v
	apio verify

build: all.v
	apio build

upload: all.v
	apio upload
