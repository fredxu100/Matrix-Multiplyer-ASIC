`include "uvm_macros.svh"
import uvm_pkg::*;

class matrix_tx_en extends matrix_tx;
    `uvm_object_utils(matrix_tx_en)

    rand logic en [7:0]; //'{default: 1'b1};

    function new (string name = "matrix_tx");
        super.new(name);
    endfunction

    //NOTE: MAKE SURE TO ADD TRANSACTIONS TESTING CORNER CASES FOR RST/EN
    /*constraint rst_dist {
        foreach (rst[i]) {
            rst[i] dist { 1'b1 := 1, 1'b0 := 99 };
        }
    }*/

    constraint en_dist {
        foreach (en[i]) {
            en[i] dist { 1'b1 := 80, 1'b0 := 20 };
        }
    }

endclass