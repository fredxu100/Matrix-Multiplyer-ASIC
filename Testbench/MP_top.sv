import uvm_pkg::*;
`include "uvm_macros.svh"

module top();

    bit clk;
    always #10 clk = ~clk;

    MP_intf intf(clk);
    MP_v3 dut0(.Ain1(intf.Ain1), .Ain2(intf.Ain2), .Bin1(intf.Bin1), .Bin2(intf.Bin2),
                .clk(clk), .en(intf.en), .rst(intf.rst),
                .results(intf.results)
                );

    initial begin
        uvm_config_db#(virtual MP_intf)::set(null, "*", "vif", intf);
        run_test("MP_test");
    end

endmodule