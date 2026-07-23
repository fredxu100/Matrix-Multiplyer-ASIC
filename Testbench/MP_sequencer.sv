`include "uvm_macros.svh"
import uvm_pkg::*;

class MP_sequencer extends uvm_sequencer #(matrix_tx) ;
    `uvm_component_utils(MP_sequencer)

    function new(string name = "MP_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass