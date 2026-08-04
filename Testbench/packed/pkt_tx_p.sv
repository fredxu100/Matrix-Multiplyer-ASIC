`include "uvm_macros.svh"
import uvm_pkg::*;

class pkt_tx extends uvm_sequence_item;
    `uvm_object_utils(pkt_tx)
    
    logic rst = 1'b0;
    logic en = 1'b1;
    rand logic [31:0] Ain1, Ain2, Bin1, Bin2;
    logic [151:0] results;
    
    function new (string name = "pkt_tx");
        super.new(name);
    endfunction
    
endclass