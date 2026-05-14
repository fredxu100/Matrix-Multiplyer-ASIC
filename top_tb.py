import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly
from cocotb.queue import Queue
import top_transaction
import top_coverage


@cocotb.test()
async def main(dut):
    in_queue = Queue()
    out_queue = Queue()
    top_cov = top_coverage.Coverage()

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())

    dut.rst.value = 1
    dut.cpu_store_signal.value = 0
    dut.data.value = 0

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    cocotb.start_soon(monitor(dut, out_queue, top_cov))
    cocotb.start_soon(scoreboard(in_queue, out_queue))

    while top_cov.get_percentage() < 100:
        cocotb.log.info(f"Coverage: {top_cov.get_percentage():.1f}%")
        tx = top_transaction.Transaction()
        tx.randomize()
        in_queue.put_nowait(tx)
        await driver(dut, tx)

async def driver(dut, tx: top_transaction.Transaction):
    for word in tx.data_words:
        await RisingEdge(dut.clk)
        dut.data.value            = word
        dut.cpu_store_signal.value = 1
        await RisingEdge(dut.clk)
        dut.cpu_store_signal.value = 0

    # Wait for FSM to enter the execution / compute state (en == 0x00)
    # en goes to 0 after the 8th store; the always_ff updates on the next
    # posedge, so we poll until it is actually 0.
    while int(dut.en.value) != 0:
        await RisingEdge(dut.clk)


async def monitor(dut, out_queue: Queue, top_cov: top_coverage.Coverage):
    prev_en = None

    while True:
        await RisingEdge(dut.clk)
        await ReadOnly()
        cur_en = int(dut.en.value)

        if cur_en == 0 and prev_en != 0:
            # Allow one extra cycle for results to propagate through the systolic array's registered output (adjust if needed).
            await RisingEdge(dut.clk)
            await ReadOnly()

            tx = top_transaction.Transaction()

            # dut.results is declared as [15:0][15:0] in SV.
            try:
                # Try direct 2-D indexing first (works with VCS / Xcelium)
                matrix = [
                    [int(dut.results[r][c].value) for c in range(16)]
                    for r in range(16)
                ]
            except (AttributeError, TypeError):
                # results[r][c] → flat index = r*16 + c
                raw = int(dut.results.value)
                matrix = []
                for r in range(16):
                    row = []
                    for c in range(16):
                        idx       = r * 16 + c          # element index
                        bit_lo    = idx * 32
                        cell_val  = (raw >> bit_lo) & 0xFFFF_FFFF
                        row.append(cell_val)
                    matrix.append(row)

            tx.results_matrix = matrix
            out_queue.put_nowait(tx)
            top_cov.sample(tx)

        prev_en = cur_en

async def scoreboard(in_queue: Queue, out_queue: Queue):
    # Accumulated expected state – persists across transactions
    expected_acc = [[0] * 16 for _ in range(16)]

    while True:
        tx_in  = await in_queue.get()
        tx_out = await out_queue.get()

        a_in, b_in = tx_in.get_pe_inputs()   # both lists have 4 elements

        # Update reference model
        for r in range(16):
            for c in range(16):
                # Only the first 4 rows / cols receive non-zero inputs
                a_val = a_in[r] if r < len(a_in) else 0
                b_val = b_in[c] if c < len(b_in) else 0
                expected_acc[r][c] += a_val * b_val

        # Compare against DUT
        mismatches = []
        for r in range(16):
            for c in range(16):
                actual   = tx_out.results_matrix[r][c]
                expected = expected_acc[r][c]
                if actual != expected:
                    mismatches.append(
                        f"  PE[{r}][{c}]: expected {expected} got {actual}"
                    )

        if mismatches:
            mismatch_str = "\n".join(mismatches)
            raise AssertionError(
                f"Scoreboard MISMATCH in transaction:\n{mismatch_str}"
            )

        cocotb.log.info("Scoreboard: transaction verified ✓")