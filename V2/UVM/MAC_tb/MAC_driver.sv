class driver extends uvm_driver #(MAC_tx);
    `uvm_component_utils(driver)

    MAC_tx tx;
    virtual MAC_intf.drv_if vif;

    function new(string name = "driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual MAC_intf)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV", "Could not get vif");
        end
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        // 1. Initial reset state (before the first clock edge)
        vif.drv_cb.ain <= 8'h0;
        vif.drv_cb.bin <= 8'h0;
        vif.drv_cb.en  <= 1'b0;
        vif.drv_cb.rst <= 1'b1;

        forever begin
            seq_item_port.get_next_item(tx);

            // 3. Wait for the clock BEFORE driving anything
            @(vif.drv_cb);

            vif.drv_cb.ain <= tx.ain;
            vif.drv_cb.bin <= tx.bin;
            vif.drv_cb.en  <= tx.en;
            vif.drv_cb.rst <= tx.rst;

            // 5. Signal that we are done with this transaction
            seq_item_port.item_done();
        end
    endtask

endclass