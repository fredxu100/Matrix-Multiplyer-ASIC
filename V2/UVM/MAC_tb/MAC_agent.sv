`include "uvm_macros.svh"
import uvm_pkg::*;

class MAC_agent extends uvm_agent;

    MAC_driver drv;
    MAC_coverage cov;
    MAC_monitor mon;
    MAC_sequencer seqncr;

    function new (string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function build_phase (uvm_phase phase);
        super.build_phase(phase);
        cov = MAC_coverage::type_id::create("cov", this);
        mon = MAC_monitor::type_id::create("mon", this);
        if(get_is_active()) begin
            drv = MAC_driver::type_id::create("drv", this);
            seqncr = MAC_sequencer::type_id::create("seqncr", this);
        end
    endfunction

    function connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        mon.mon_ap.connect(cov.analysis_export);

        if (get_is_active()) begin
            drv.seq_item_port.connect(seqncr.seq_item_export);
        end
    endfunction
endclass