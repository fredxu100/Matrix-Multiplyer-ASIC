`include "uvm_macros.svh"
import uvm_pkg::*;
 
class MP_monitor extends uvm_monitor;
    `uvm_component_utils(MP_monitor)
 
    virtual MP_intf.mon_if vif;
    pkt_tx pkt;
    uvm_analysis_port #(pkt_tx) pkt_ap;
 
    function new(string name = "MP_monitor", uvm_component parent);
        super.new(name, parent);
        pkt_ap = new("pkt_ap", this); 
    endfunction

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual MP_intf)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON", "Failed to connnect intf to mon")
        end
    endfunction

    task run_phase (uvm_phase phase);
        super.run_phase(phase);
        
        forever begin
            @(vif.mon_cb);
            // NOTE: must write every cycle (not just when en=1)
            pkt = pkt_tx::type_id::create("tx");
            pkt.results = vif.mon_cb.results;
            pkt.en = vif.mon_cb.en;
            pkt.rst = vif.mon_cb.rst;
            pkt.Ain1 = vif.mon_cb.Ain1;
            pkt.Ain2 = vif.mon_cb.Ain2;
            pkt.Bin1 = vif.mon_cb.Bin1;
            pkt.Bin2 = vif.mon_cb.Bin2;

            pkt_ap.write(pkt);
        end
    endtask
endclass