#SYNTHESIS
set ::env(DESIGN_NAME) "MP_v3"
set ::env(SYNTH_USE_SYSTEMVERILOG) "1"

# Silence ABC combinational error
set ::env(SYNTH_STRATEGY) "DELAY 0" 

# Verilog Source Files
set ::env(VERILOG_FILES) "\
    $::env(DESIGN_DIR)/src/MAC_v3.sv \
    $::env(DESIGN_DIR)/src/systollic_v3.sv \
    $::env(DESIGN_DIR)/src/MP_v3.sv"

# SDC Constraints File
set ::env(BASE_SDC_FILE) "$::env(DESIGN_DIR)/constraints.sdc"

# PDK & Process Node Configuration
set ::env(PDK) "sky130A"
set ::env(STD_CELL_LIBRARY) "sky130_fd_sc_hd"

# Clock Port Name & Period (Matches SDC)
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "10.0"