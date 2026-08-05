#--------------CORE/DIE BOUNDARY CONSTRAINTS--------------#
set ::env(FP_SIZING) "relative"

# 60% target due to dense arithmetic/routing 
#NOTE: THIS CAN BE OPTMIZED TO REDUCE COSTS, SET REALLY LOW DUE TO CNSTR
# 499,682.9856 STANDARD CELL AREA
set ::env(FP_CORE_UTIL) 40
set ::env(FP_ASPECT_RATIO) 1.0

#-------------PIN/IO CONSTRAINTS------------#
#TEMPORARILY DISABLE, PIN CFG NOT WORKING
# set ::env(FP_PIN_ORDER_CFG) "$::env(DESIGN_DIR)/pin_order.cfg"

# Pin Placement Mode: 0 = random, 1 = equidistant, 2 = Hungarian algorithm
set ::env(FP_IO_MODE) 1