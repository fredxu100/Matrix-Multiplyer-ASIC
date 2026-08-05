# ==============================================================================
# MASTER CONFIG.TCL - MP_v3
# ==============================================================================

# --- Load Synthesis Configuration ---
source "$::env(DESIGN_DIR)/synthesis.tcl"

# --- Load Floorplan Configuration ---
source "$::env(DESIGN_DIR)/floorplan.tcl"

# --- Load PDN Configuration ---
source "$::env(DESIGN_DIR)/pdn.tcl"

#-------------CONSTRAINT CHANGES------------#

#NOTE: AREA TRADEOFF, CAN BE OPTIMIZED
set ::env(PL_TARGET_DENSITY) 0.45