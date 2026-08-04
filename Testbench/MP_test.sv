`include "uvm_macros.svh"
import uvm_pkg::*;

class MP_test extends uvm_test;
    `uvm_component_utils(MP_test)

    MP_environment env;
    int cover_percent;
    virtual MP_intf vif;

    function new(string name = "MP_test", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase (uvm_phase phase);
        //MATRIX TYPE OVERRIDE FOR DIFFERENT TRANSACTIONS
        //set_type_override_by_type(matrix_tx::get_type(), matrix_tx_en::get_type()); 
        
        super.build_phase(phase);
        env = MP_environment::type_id::create("MP_env", this);
        if (!uvm_config_db#(virtual MP_intf)::get(this, "", "vif", vif)) begin
            `uvm_fatal("TEST", "Could not get vif")
        end
    endfunction

    task run_phase (uvm_phase phase);
        int max_attempts = 1000;
        int attempts = 0;
        phase.raise_objection(this);

        //env.agnt.cov.cg_tx.get_inst_coverage(), use for coverage later
        while (attempts < max_attempts) begin
            MP_sequence_rand seq = MP_sequence_rand::type_id::create("seq");
            seq.start(env.agnt.seqncr);
            attempts++;
        end

        // Drain: let the last transactions flush through the DUT/reference
        repeat (40) @(posedge vif.clk);

        phase.drop_objection(this);
    endtask

endclass