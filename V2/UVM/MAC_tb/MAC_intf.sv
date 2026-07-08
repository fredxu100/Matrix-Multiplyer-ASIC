interface MAC_intf (input logic clk);

    logic [7:0] ain, bin;
    logic en, rst;
    logic [7:0] aout, bout;
    logic [24:0] accumulator;

    clocking drv_cb @(posedge clk);
        default output #1ns;
        output ain, bin, en, rst;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input aout, bout, accumulator;
    endclocking

    modport drv_if (clocking drv_cb);
    modport mon_if (clocking mon_cb);

endinterface