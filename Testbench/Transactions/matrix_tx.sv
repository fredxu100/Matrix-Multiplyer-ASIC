`include "uvm_macros.svh"
import uvm_pkg::*;

class matrix_tx extends uvm_sequence_item;
    `uvm_object_utils(matrix_tx)
    
    rand logic [7:0] A_matrix [7:0][7:0];
    rand logic [7:0] B_matrix [7:0][7:0];
    logic [18:0] results_matrix [7:0][7:0];

    // NOTE: added - MP_driver drives tx.rst / tx.en for the full 8-cycle load,
    // but those fields never existed on this class (compile error).
    logic rst = 1'b0;
    logic en = 1'b1;

    function new (string name = "matrix_tx");
        super.new(name);
    endfunction

    //NOTE: MAKE SURE TO ADD TRANSACTIONS TESTING CORNER CASES FOR RST/EN
    /*constraint rst_dist {
        rst dist { 1 := 1, 0 := 99 };
    }

    constraint en_dist {
        en dist { 1 := 95, 0 := 5 };
    }*/

endclass