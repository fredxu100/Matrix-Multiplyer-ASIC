module top();

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    bit clk;
    always #10 clk = ~clk;

    MAC_intf intf(clk);
    MAC_v2 dut0(.ain(intf.ain), .bin(intf.bin),
                .clk(clk), .en(intf.en), .rst(intf.rst),
                .aout(intf.aout), .bout(intf.bout),
                .accumulator(intf.accumulator)
                );

    initial begin
        uvm_config_db #(virtual MAC_intf)::set(null, "uvm_test_top", "vif", intf);
        run_test("MAC_test");
    end

endmodule