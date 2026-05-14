# Simulator selection
SIM              ?= icarus
TOPLEVEL_LANG    ?= verilog
 
VERILOG_SOURCES += $(OUT_DIR)/synthesis/MAC.sv
VERILOG_SOURCES += $(PDK_ROOT)/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v
TOPLEVEL = MAC  # Or whatever sub-module you are isolating
MODULE = MAC_tb
 
# Pull in cocotb's build system
include $(shell cocotb-config --makefiles)/Makefile.sim
 