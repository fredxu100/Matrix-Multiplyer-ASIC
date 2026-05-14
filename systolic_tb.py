import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly
from cocotb.queue import Queue
import systolic_transaction

@cocotb.test()
async def main(dut):
    in_queue = Queue()
    out_queue = Queue()

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    cocotb.start_soon(monitor(dut, out_queue)) 
    cocotb.start_soon(scoreboard(in_queue, out_queue))
    await RisingEdge(dut.clk) #clk 0

    for i in range(500):
        tx = systolic_transaction.Transaction()
        tx.randomize()
        in_queue.put_nowait(tx)
        await driver(dut, tx)

async def driver(dut, tx):
    dut.en.value = tx.en
    dut.rst.value = tx.rst
    # Pack list into a single integer (a[0] in MSB, a[15] in LSB)
    a_packed = 0
    b_packed = 0
    for i in range(16):
        a_packed |= (tx.a[i] & 0xFF) << ((15 - i) * 8)
        b_packed |= (tx.b[i] & 0xFF) << ((15 - i) * 8)

    dut.a.value = a_packed
    dut.b.value = b_packed
    await RisingEdge(dut.clk)

async def monitor(dut, out_queue):
     while True:
        await RisingEdge(dut.clk)
        await ReadOnly()

        # Skip if in reset
        if dut.rst.value == 1:
            continue

        # Guard against X/Z on packed ports by wrapping in try/except
        try:
            tx = systolic_transaction.Transaction()
            tx.en  = int(dut.en.value)
            tx.rst = int(dut.rst.value)

            # Unpack packed input ports [15:0][7:0] → list of 16 bytes
            a_val = int(dut.a.value)
            b_val = int(dut.b.value)
            tx.a = [(a_val >> ((15 - i) * 8)) & 0xFF for i in range(16)]
            tx.b = [(b_val >> ((15 - i) * 8)) & 0xFF for i in range(16)]

            # Capture 2D results (unpacked, so element access is fine)
            tx.results = []
            for r in range(16):
                row_val = int(dut.results[r].value)
                tx.results.append([
                    (row_val >> ((15 - c) * 32)) & 0xFFFFFFFF for c in range(16)
                ])

            out_queue.put_nowait(tx)

        except ValueError as e:
            # X/Z present on a signal — skip this cycle
            cocotb.log.warning(f"Monitor skipping cycle due to unresolved value: {e}")
            continue

async def scoreboard(in_queue, out_queue):

    size = 16
    expected_results = [[0] * size for _ in range(size)]
    row_pipe = [[0] * (size + 1) for _ in range(size)]
    col_pipe = [[0] * size for _ in range(size + 1)]
    
    # One-cycle delay buffer: hold the expected state that corresponds
    # to what the hardware will OUTPUT next cycle
    prev_expected = [[0] * size for _ in range(size)]

    while True:
        tx = await out_queue.get()

        if tx.rst == 1:
            expected_results = [[0] * size for _ in range(size)]
            prev_expected    = [[0] * size for _ in range(size)]
            row_pipe = [[0] * (size + 1) for _ in range(size)]
            col_pipe = [[0] * size for _ in range(size + 1)]
            continue

        # Compare against PREVIOUS cycle's expected — that's what the
        # hardware has had time to register and drive onto results[]
        mismatches = 0
        for r in range(size):
            for c in range(size):
                actual   = tx.results[r][c]
                expected = prev_expected[r][c]
                if actual != expected:
                    cocotb.log.error(
                        f"Mismatch at PE[{r}][{c}] | "
                        f"Expected: 0x{expected:08X} | Got: 0x{actual:08X}"
                    )
                    mismatches += 1

        if mismatches > 0:
            raise AssertionError(f"Scoreboard failed with {mismatches} mismatches.")

        # Now advance the reference model with THIS cycle's inputs,
        # storing result into expected_results for comparison NEXT cycle
        if tx.en == 1:
            for i in range(size):
                row_pipe[i][0] = int(tx.a[i])
                col_pipe[0][i] = int(tx.b[i])

            row_snap = [row[:] for row in row_pipe]
            col_snap = [col[:] for col in col_pipe]

            for r in range(size):
                for c in range(size):
                    ain  = row_snap[r][c]
                    bin_ = col_snap[r][c]
                    expected_results[r][c] = (
                        expected_results[r][c] + ain * bin_
                    ) & 0xFFFFFFFF
                    row_pipe[r][c + 1] = ain
                    col_pipe[r + 1][c] = bin_

        # Promote current expected → prev so next iteration compares correctly
        prev_expected = [row[:] for row in expected_results]