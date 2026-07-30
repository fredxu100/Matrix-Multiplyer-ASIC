`include "uvm_macros.svh"
import uvm_pkg::*;

class matrix_tx_rst extends matrix_tx;
    `uvm_object_utils(matrix_tx_rst)

    rand logic rst [7:0]; //'{default: 1'b1};

    function new (string name = "matrix_tx_rst");
        super.new(name);
    endfunction

    //NOTE: MAKE SURE TO ADD TRANSACTIONS TESTING CORNER CASES FOR RST/EN
    constraint rst_dist {
        foreach (rst[i]) {
            rst[i] dist { 1'b1 := 1, 1'b0 := 99 };
        }
    }

endclass