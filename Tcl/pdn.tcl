#--------------------PDN CONSTRAINTS------------------------#
set ::env(VDD_NETS) [list "VDD"]
set ::env(GND_NETS) [list "VSS"]

# Enable Core Power Ring
set ::env(FP_PDN_CORE_RING) 1

#CUSTOM WIDTHS
# set ::env(FP_PDN_CORE_RING_VWIDTH) 3.1
# set ::env(FP_PDN_CORE_RING_HWIDTH) 3.1
# set ::env(FP_PDN_CORE_RING_VOFFSET) 6.0
# set ::env(FP_PDN_CORE_RING_HOFFSET) 6.0