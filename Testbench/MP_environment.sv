`include "uvm_macros.svh"
import uvm_pkg::*;

class MP_environment extends uvm_env;
    `uvm_component_utils(MP_environment)

    MP_scoreboard scb;
    MP_agent agnt;

    function new(string name = "MP_environment", uvm_component parent);
        super.new(name, parent);
    endfunction 

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        scb = MP_scoreboard::type_id::create("MP_scb", this);
        agnt = MP_agent::type_id::create("MP_agnt", this);
    endfunction

    function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        agnt.mon.pkt_ap.connect(scb.pkt_imp);
        agnt.drv.matrix_ap.connect(scb.matrix_imp);
    endfunction

endclass