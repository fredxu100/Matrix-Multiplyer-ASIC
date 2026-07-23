`include "uvm_macros.svh"
import uvm_pkg::*;

class MP_agent extends uvm_agent;
    `uvm_component_utils(MP_agent)
    
    MP_driver drv;
    MP_coverage cov;
    MP_monitor mon;
    MP_sequencer seqncr;

    function new (string name = "MP_agent", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        cov = MP_coverage::type_id::create("MP_cov", this);
        mon = MP_monitor::type_id::create("MP_mon", this);
        if(get_is_active()) begin
            drv = MP_driver::type_id::create("MP_drv", this);
            seqncr = MP_sequencer::type_id::create("MP_seqncr", this);
        end
    endfunction

    function void connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        mon.pkt_ap.connect(cov.analysis_export);
        if (get_is_active()) begin
            drv.seq_item_port.connect(seqncr.seq_item_export);
        end
    endfunction
endclass