
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

set ::env(SDC_FILE) "$::env(DESIGN_DIR)/src/spm.sdc"

# Ensure extra timing reports are generated
set ::env(RUN_SPEF_EXTRACTION) 1
set ::env(RCX_STATS_OUTPUT) "reports/signoff/rcx_stats.rpt"

# Keep these to allow detailed manual analysis in OpenROAD later
set ::env(QUIT_ON_TIMING_VIOLATIONS) 0
set ::env(QUIT_ON_MAGIC_DRC) 0

# Increase the reporting threshold so you see all paths, not just the worst ones
set ::env(STA_REPORT_POWER) 1
set ::env(STA_REPORT_HOLD) 1
