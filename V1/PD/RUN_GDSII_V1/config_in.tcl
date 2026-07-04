
set ::env(DESIGN_NAME) {axi_wrapper}
set ::env(VERILOG_FILES) [glob $::env(DESIGN_DIR)/src/*.{v,sv}]
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "10.0"

set ::env(DESIGN_IS_CORE) {1}

set tech_specific_config "$::env(DESIGN_DIR)/$::env(PDK)_$::env(STD_CELL_LIBRARY)_config.tcl"
if { [file exists $tech_specific_config] == 1 } {
    source $tech_specific_config
}

set ::env(DIE_AREA) {0 0 4000 4000}
set ::env(FP_IO_MODE) 2
