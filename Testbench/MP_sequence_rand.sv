`include "uvm_macros.svh"
import uvm_pkg::*;

class MP_sequence_rand extends uvm_sequence #(matrix_tx);
    `uvm_object_utils(MP_sequence_rand)

    function new(string name = "MP_sequence_rand");
        super.new(name);
    endfunction

    task body();
        matrix_tx tx = matrix_tx::type_id::create("matrix_tx");
        
        start_item(tx);
        if (!tx.randomize()) begin
            `uvm_error("SEQ", "Randomization failed");
        end
        finish_item(tx);
    endtask
endclass