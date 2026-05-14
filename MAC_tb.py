import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly
from cocotb.queue import Queue
from collections import deque
import MAC_transaction
import MAC_coverage

@cocotb.test()
async def main(dut):
    in_queue = Queue()
    out_queue = Queue()
    MAC_cov = MAC_coverage.MAC_coverage()

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    
    # Reset Sequence
    dut.rst.value = 1
    dut.en.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)

    cocotb.start_soon(monitor(dut, out_queue, MAC_cov)) 
    cocotb.start_soon(scoreboard(in_queue, out_queue))

    # Coverage loop
    while MAC_cov.coverage() < 100:
        tx = MAC_transaction.Transaction()
        tx.randomize()
        in_queue.put_nowait(tx)
        await driver(dut, tx)
        
    # Allow a few extra cycles to clear the 2-cycle latency
    for _ in range(5):
        await RisingEdge(dut.clk)

async def driver(dut, tx):
    dut.ain.value = tx.ain
    dut.bin.value = tx.bin
    dut.en.value = tx.en
    dut.rst.value = tx.rst
    await RisingEdge(dut.clk)

async def monitor(dut, out_queue, MAC_cov):
    while True:
        await RisingEdge(dut.clk)
        await ReadOnly()
        
        if dut.accumulator.value.is_resolvable:
            tx = MAC_transaction.Transaction()
            # Capture current state of the pins
            tx.ain = int(dut.ain.value)
            tx.bin = int(dut.bin.value)
            tx.en = int(dut.en.value)
            tx.rst = int(dut.rst.value)
            tx.accumulator = int(dut.accumulator.value)
            
            out_queue.put_nowait(tx)
            MAC_cov.sample(tx.ain, tx.bin, tx.en, tx.rst, tx.accumulator)

async def scoreboard(in_queue, out_queue):
    pipeline_delay = 2 # Matches your RTL latency
    history = deque()
    current_model_acc = 0

    while True:
        tx_in = await in_queue.get()
        tx_out = await out_queue.get()

        # Model the logic cycle-by-cycle
        if tx_in.rst == 1:
            current_model_acc = 0
        elif tx_in.en == 1:
            product = tx_in.ain * tx_in.bin
            current_model_acc = (current_model_acc + product) & 0xFFFFFFFF
        
        # Always push to history, even during reset
        # This acts as the physical delay of the registers
        history.append(current_model_acc)

        # Only compare once the pipe is full
        if len(history) > pipeline_delay:
            expected = history.popleft()
            actual = tx_out.accumulator
            
            assert expected == actual, \
                f"MAC Mismatch! Exp: {expected} | Act: {actual}"