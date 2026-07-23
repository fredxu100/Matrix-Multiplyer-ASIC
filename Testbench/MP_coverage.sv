`include "uvm_macros.svh"
import uvm_pkg::*;

class MP_coverage extends uvm_subscriber #(pkt_tx);
    `uvm_component_utils(MP_coverage)

    pkt_tx tx;

    covergroup cg_tx with function sample(pkt_tx tx);
        
        option.per_instance = 1;
        
        cp_Ain1: coverpoint tx.Ain1 {
            bins special   = {0}; 
        }
        cp_Bin1: coverpoint tx.Bin1 {
            bins special = {0};
        }
        cp_Ain2: coverpoint tx.Ain2 {
            bins special   = {0}; 
        }
        cp_Bin2: coverpoint tx.Bin2 {
            bins special = {0};
        }

        cp_rst: coverpoint tx.rst;
    endgroup
    
    function new(string name = "MP_coverage", uvm_component parent);
        super.new(name, parent);
        cg_tx = new();
    endfunction

    function void write(pkt_tx t);
        tx = t;
        cg_tx.sample(tx);
    endfunction

endclass