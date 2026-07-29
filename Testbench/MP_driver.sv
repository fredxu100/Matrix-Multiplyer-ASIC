`include "uvm_macros.svh"
import uvm_pkg::*;

class MP_driver extends uvm_driver #(matrix_tx);
    `uvm_component_utils(MP_driver)
 
    matrix_tx tx;
    virtual MP_intf.drv_if vif;
    uvm_analysis_port #(matrix_tx) matrix_ap;
 
    function new(string name = "MP_driver", uvm_component parent);
        super.new(name, parent);
        matrix_ap = new("matrix_ap", this);
    endfunction
 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(virtual MP_intf)::get(this, "", "vif", vif)) begin
            `uvm_fatal("DRV", "Could not get vif");
        end
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
 
        // Initial reset state (before the first clock edge)
        @(vif.drv_cb);
        vif.drv_cb.Ain1 <= '0;
        vif.drv_cb.Bin1 <= '0;
        vif.drv_cb.Ain2 <= '0;
        vif.drv_cb.Bin2 <= '0;
        vif.drv_cb.en  <= '0;
        vif.drv_cb.rst <= 1'b1;

        @(vif.drv_cb);
        vif.drv_cb.rst <= 1'b0;
        @(vif.drv_cb);   // let rst=0 be sampled cleanly one cycle before en/data ever rise
 
        forever begin
            seq_item_port.get_next_item(tx);

            // Wait for the clock BEFORE driving anything
            for (int i = 0; i < 8; i++) begin         

                @(vif.drv_cb); //WAIT FOR NEXT CLOCK CYCLE!!!!
                if (i == 0) matrix_ap.write(tx);

                //splitting up values - drive through the clocking block, not the bare signal
                vif.drv_cb.Ain1 <= {tx.A_matrix[i][3], tx.A_matrix[i][2], tx.A_matrix[i][1], tx.A_matrix[i][0]};
                vif.drv_cb.Ain2 <= {tx.A_matrix[i][7], tx.A_matrix[i][6], tx.A_matrix[i][5], tx.A_matrix[i][4]};
                vif.drv_cb.Bin1 <= {tx.B_matrix[i][3], tx.B_matrix[i][2], tx.B_matrix[i][1], tx.B_matrix[i][0]};
                vif.drv_cb.Bin2 <= {tx.B_matrix[i][7], tx.B_matrix[i][6], tx.B_matrix[i][5], tx.B_matrix[i][4]};

                vif.drv_cb.rst  <= tx.rst;
                vif.drv_cb.en   <= tx.en;
            end
            // Signal that we are done with this transaction
            seq_item_port.item_done();
        end
    endtask
endclass