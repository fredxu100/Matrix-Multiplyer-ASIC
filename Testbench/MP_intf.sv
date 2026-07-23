interface MP_intf (input logic clk);

    logic rst, en;
    logic [31:0] Ain1, Ain2, Bin1, Bin2;
    logic [18:0] results [7:0];

    clocking drv_cb @(posedge clk);
        default output #1ns;
        output Ain1, Ain2, Bin1, Bin2, en, rst;
    endclocking

    clocking mon_cb @(posedge clk);
        default input #1step;
        input results, en, rst, Ain1, Ain2, Bin1, Bin2;
    endclocking

    modport drv_if (clocking drv_cb);
    modport mon_if (clocking mon_cb);

endinterface