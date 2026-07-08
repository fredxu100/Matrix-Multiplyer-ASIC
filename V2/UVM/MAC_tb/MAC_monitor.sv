class MAC_monitor extends uvm_monitor;
    `uvm_component_utils(MAC_monitor)

    virtual MAC_intf.mon_if vif;
    MAC_tx tx;
    uvm_analysis_port #(MAC_tx) mon_ap;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        mon_ap = new("mon_ap", this); //name, parent(mon)
    endfunction

    function build_phase (uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual MAC_intf)::get(this, "", "vif", vif)) begin
            `uvm_fatal("MON", "Failed to connnect intf to mon")
        end
    endfunction

    task run_phase (uvm_phase phase);
        super.run_phase(phase);
        
        forever begin
            @(vif.mon_cb);
            if (vif.mon_cb.en) begin 
                tx = MAC_tx::type_id::create("tx");
                tx.aout = vif.mon_cb.aout;         // Sample via Clocking Block
                tx.bout = vif.mon_cb.bout;         // Sample via Clocking Block
                tx.accumulator = vif.mon_cb.accumulator;
                mon_ap.write(tx);
            end  
        end
    endtask
endclass