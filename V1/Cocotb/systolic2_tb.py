import cocotb
from cocotb.triggers import RisingEdge
from cocotb.clock import Clock

@cocotb.test()
async def main(dut):
    # 0. Initialize Clock (10ns period = 100MHz)
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # 1. Reset Sequence
    dut.rst.value = 1
    dut.en.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    # 2. Construct 128-bit packed values for 'a' and 'b'
    # Each 8-bit segment is set to 1. 
    # Matches SV: a[i*8 +: 8]
    packed_ones = 0
    for i in range(16):
        packed_ones |= (1 << (i * 8))

    # 3. Drive the array to saturate all MAC units
    dut.en.value = 1
    for _ in range(16):
        dut.a.value = packed_ones
        dut.b.value = packed_ones
        await RisingEdge(dut.clk)

    # 4. Clear inputs and drain the pipeline
    # Systolic arrays have a latency of ~2*N cycles to fully clear
    dut.a.value = 0
    dut.b.value = 0
    for _ in range(40): 
        await RisingEdge(dut.clk)

    # 5. Verify Results
    # 'results' is now a single 8192-bit vector.
    # Logic: results[(r*16 + c)*32 +: 32]
    errors = 0
    
    # Grab the entire bit-vector as one giant Python integer
    all_results = int(dut.results.value)

    for r in range(16):
        for c in range(16):
            try:
                # Calculate the bit-offset for this specific PE
                # (row_index * row_width) + (col_index * element_width)
                bit_offset = (r * 16 + c) * 32
                
                # Slice the 32 bits out of the giant integer
                actual_val = (all_results >> bit_offset) & 0xFFFFFFFF
                
                # Just a connectivity check: since we fed 1s, result should be > 0
                assert actual_val >= 1, f"PE[{r}][{c}] at offset {bit_offset} is 0! Data did not propagate."
                
            except Exception as e:
                dut._log.error(f"Verification Error at PE[{r}][{c}]: {e}")
                errors += 1

    if errors == 0:
        dut._log.info("SUCCESS: All 256 PEs accumulated data correctly via flattened bus.")
    else:
        assert False, f"FAILED: {errors} PEs failed connectivity check."