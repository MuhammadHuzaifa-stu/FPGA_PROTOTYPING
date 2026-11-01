SHELL := /bin/bash
VIVADO_ENV = source ~/.xilinx_env

.PHONY: all hw synthesis implementation bitstream clean

# Default target: builds everything (all -> hw -> bitstream)
all: hw

hw: bitstream

# 1. Synthesis Target
synthesis:
	@echo "=== Target: Synthesis ==="
	@mkdir -p build
	@$(SHELL) -c "$(VIVADO_ENV) && vivado -mode batch -source scripts/build_hw.tcl -tclargs synth -log build/vivado_synth.log -jou build/vivado_synth.jou"

# 2. Implementation Target
implementation:
	@echo "=== Target: Implementation ==="
	@mkdir -p build
	@$(SHELL) -c "$(VIVADO_ENV) && vivado -mode batch -source scripts/build_hw.tcl -tclargs impl -log build/vivado_impl.log -jou build/vivado_impl.jou"

# 3. Bitstream Generation Target
bitstream:
	@echo "=== Target: Bitstream Generation ==="
	@mkdir -p build
	@$(SHELL) -c "$(VIVADO_ENV) && vivado -mode batch -source scripts/build_hw.tcl -tclargs bitstream -log build/vivado_bitstream.log -jou build/vivado_bitstream.jou"

# Clean build logs and temp files
clean:
	rm -rf build/ .Xil/ *.log *.jou