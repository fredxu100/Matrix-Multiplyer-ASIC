# -------------------CLOCK DEFINITION---------------------#
# 100 MHz clock on clk pin
create_clock -name core_clk -period 10.0000 [get_ports clk]

# Reserve 0.3 ns (300 ps) margin for jitter and skew
set_clock_uncertainty 0.3000 [get_clocks core_clk]

# Estimate 0.5 ns latency from clock source to chip boundary
set_clock_latency 0.5000 [get_clocks core_clk]

# --------------------I/O DELAYS (RISC-V)------------------#
#PROVIDES INTERNAL TIMING BUDGET FOR INTERNAL LOGIC TO WORK WITH BASED ON EXTERNAL I/O
#!VERIFY DELAY TIMING!

#NOTE: Bc synchronous reset, 50/50 rule, 5ns reserved for rst delay for FANOUT
set_input_delay -max 5.000 -clock [get_clocks core_clk] [get_ports rst]
#!VERIFY! Fastest possible arrival time of signal from outside chip based on RISC-V
# Outgoing data/signals: External receiver requires data 0.5 ns before the next edge.
set_input_delay -min 1.500 -clock [get_clocks core_clk] [get_ports rst]

#NOTE: Follows 50/50 rule
set_input_delay -max 5.000 -clock [get_clocks core_clk] [get_ports en]
set_input_delay -min 1.500 -clock [get_clocks core_clk] [get_ports en]

#NOTE: Following 60/40 rule, 60% period (6ns) reserved for data in delay, gives internal logic a 4 ns budget 
set_input_delay -max 6.000 -clock [get_clocks core_clk] [get_ports {Ain1 Ain2 Bin1 Bin2}]
set_input_delay -min 1.800 -clock [get_clocks core_clk] [get_ports {Ain1 Ain2 Bin1 Bin2}]

#NOTE: Also follows 60/40 rule 
set_output_delay -max 6.000 -clock [get_clocks core_clk] [get_ports {results}]
#VERIFY OUTPUT MIN
set_output_delay -min 0.200 -clock [get_clocks core_clk] [get_ports {results}]


# --------------------ELECTRICAL/ENVIRONMENT CONSTRAINTS----------------#

#VERIFY THAT I HAVE PDK
# (sky130_fd_sc_hd__inv_2) to calculate realistic input transition/slew rates.
set_driving_cell -lib_cell sky130_fd_sc_hd__inv_2 [get_ports {Ain1 Ain2 Bin1 Bin2 en rst}]

# !VERIFY! Output Load: Define external pin capacitive load 
set_load -pin_load 0.050 [get_ports {results}]

# Max Fanout: Prevents a single gate from driving too many loads (e.g., max 20 gates)
set_max_fanout 20 [current_design]

# Max Transition: 10-15% of clk period
# set_max_transition 1.500 [current_design]

# !VERIFY! Max Capacitance pF: Prevents excessive wire/pin loading on internal gates
# set_max_capacitance 0.500 [current_design]
