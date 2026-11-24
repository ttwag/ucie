VERIFY_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
REPO_DIR := $(abspath $(VERIFY_DIR)/../..)
RTL_DIR := $(REPO_DIR)/scala/generatedVerilog/logphy
VERIFY_FILELIST := $(VERIFY_DIR)/verible.filelist

.DEFAULT_GOAL := sim

.PHONY: rtl sim clean clean-rtl

# Generate LogPHY RTL.
rtl:
	cd "$(REPO_DIR)/scala" && \
		./mill runMain edu.berkeley.cs.uciedigital.logphy.MainLogicalPhy

# Run Xcelium from the verification directory.
sim: rtl
	export PATH="/share/instsww/cadence/XCELIUM2509/bin:$$PATH"; \
	export PATH="/share/instsww/cadence/XCELIUM2509/tools/bin:$$PATH"; \
	cd "$(VERIFY_DIR)" && \
		xrun -64bit -sv \
			-timescale 1ns/1ps \
			-F "$(RTL_DIR)/filelist.f" \
			-F "$(VERIFY_FILELIST)" \
			-incdir "$(RTL_DIR)" \
			-top tb_top \
			-access +rwc

clean:
	rm -rf "$(VERIFY_DIR)/xcelium.d"
	rm -f "$(VERIFY_DIR)/xrun.log" \
		"$(VERIFY_DIR)/xrun.history"

clean-rtl:
	rm -rf "$(RTL_DIR)"