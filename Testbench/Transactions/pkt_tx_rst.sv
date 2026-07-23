`include "uvm_macros.svh"
import uvm_pkg::*;

class pkt_tx_rst extends uvm_sequence_item;
    `uvm_object_utils(pkt_tx_rst)
    
    rand logic rst = 1'b0;
    logic en = 1'b1;
    rand logic [31:0] Ain1, Ain2, Bin1, Bin2;
    logic [18:0] results [7:0];
    
    function new (string name = "pkt_tx_rst");
        super.new(name);
    endfunction

    //rst edge case tests
    constraint en_dist {
        rst dist { 1 := 20, 0 := 80 };
    }
    
endclass