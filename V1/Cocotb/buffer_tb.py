import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ReadOnly
from cocotb.queue import Queue
from collections import deque
import buffer_transaction
import buffer_coverage

@cocotb.test
async def main(dut):
    in_queue = Queue()
    out_queue = Queue()
    buffer_cov = buffer_coverage.buffer_coverage()

    cocotb.start_soon(Clock(dut.clk, 10, unit="ns").start())
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)

    cocotb.start_soon(monitor(dut, out_queue, buffer_cov)) 
    cocotb.start_soon(scoreboard(in_queue, out_queue))
    await RisingEdge(dut.clk) #clk 0

    while True:
        percentage = buffer_cov.coverage()
        if percentage == 100:
            break
        tx = buffer_transaction.Transaction()
        tx.randomize()
        in_queue.put_nowait(tx)
        await driver(dut, tx)

async def driver(dut, tx):
    dut.rst.value = tx.rst
    dut.reg_in.value = tx.reg_in
    dut.r_en.value = tx.r_en
    dut.w_en.value = tx.w_en
    await RisingEdge(dut.clk) #HOLD TIME DELAY

async def monitor(dut, out_queue, buffer_cov):
    while True:
        await RisingEdge(dut.clk)
        await ReadOnly()

        if dut.reg_out.value.is_resolvable:
            tx = buffer_transaction.Transaction()
            tx.rst = int(dut.rst.value)
            tx.reg_in = int(dut.reg_in.value)
            tx.r_en = int(dut.r_en.value)
            tx.w_en = int(dut.w_en.value)
            tx.reg_out = int(dut.reg_out.value)
            tx.buffer = int(dut.buffer.value)
            out_queue.put_nowait(tx)

            #print(f"MONITOR: ren {tx.r_en} | wen {tx.w_en} | reg_in {tx.reg_in} | rst {tx.rst}")
            buffer_cov.sample(tx.r_en, tx.w_en, tx.reg_in)

async def scoreboard(in_queue, out_queue):
    expected_buffer = 0
    expected_out = 0
    prev_cycle_buffer = 0
    prev_cycle_in = 0

    while True:
        tx_in = await in_queue.get()
        tx_out = await out_queue.get()

        expected_out = prev_cycle_buffer
        expected_buffer = prev_cycle_in
        if tx_in.rst:
            prev_cycle_buffer = 0
            prev_cycle_in = 0
        else:

            if tx_in.w_en:
                prev_cycle_buffer = expected_buffer
            if tx_in.r_en:
                prev_cycle_in = tx_in.reg_in

             
            

        

        #tx_in.display()
        tx_out.display()
        print(f"  expected_buffer 0x{expected_buffer:X} | expected_out: 0x{expected_out:X}")
        # 3. Now compare against what the monitor saw at the end of this same edge
        assert expected_out == int(tx_out.reg_out), f"Mismatch! Exp: {expected_out:X} Act: {tx_out.reg_out:X}"
            
