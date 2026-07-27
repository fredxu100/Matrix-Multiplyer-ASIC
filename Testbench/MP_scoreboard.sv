`include "uvm_macros.svh"
import uvm_pkg::*;
`uvm_analysis_imp_decl(_pkt)
`uvm_analysis_imp_decl(_matrix)

class MP_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(MP_scoreboard)

    uvm_analysis_imp_matrix #(matrix_tx, MP_scoreboard) matrix_imp;
    uvm_analysis_imp_pkt #(pkt_tx, MP_scoreboard) pkt_imp;

    MP_reference rf_arr [4];
    int load_delay_cnt [4]; //used to delay scb to align with actual
    int load_counter = 0;
    int contributors;

    int num_mismatch = 0;
    int num_match = 0;
    
    pkt_tx expected_tx;
    

    // REMOVED: sys_en_delayed. 
    function new(string name = "MP_scoreboard", uvm_component parent);
        super.new(name, parent);
        matrix_imp = new("matrix_imp", this);
        pkt_imp = new("pkt_imp", this);

        foreach (rf_arr[i]) begin
            matrix_tx temp_mat = new("temp_mat");
            temp_mat.A_matrix = '{default: 8'h00};
            temp_mat.B_matrix = '{default: 8'h00};
            rf_arr[i] = new(temp_mat);
            load_delay_cnt[i] = 0;
        end
    endfunction

    function void write_matrix (matrix_tx matrix);
        $display("New matrix loaded in at %0d", (load_counter % 4));
        rf_arr[load_counter % 4] = new(matrix);

        load_delay_cnt[load_counter % 4] = 0; 

        load_counter++;
    endfunction

    function void write_pkt (pkt_tx mon_tx);
        if (mon_tx.rst) begin
            $display("SSCB RST ENABLED");
            foreach (rf_arr[i]) begin
                matrix_tx temp_mat = new("temp_mat");
                rf_arr[i] = new(temp_mat);
                load_delay_cnt[i] = 0;
            end
            return;
        end

        foreach (rf_arr[i]) begin
            if (i < load_counter && mon_tx.en) begin
                if (load_delay_cnt[i] >= 1) begin
                    rf_arr[i].stream_output();
                    //$display("SCB: rf_arr[%0d] results: %p", i, rf_arr[i].pkt.results);
                    //$display("Active Index: %p, Pipeline Depth %d\n", rf_arr[i].active_idx, rf_arr[i].pipeline_counter);
                end else begin
                    load_delay_cnt[i]++;
                end
            end
        end

        expected_tx = pkt_tx::type_id::create("expected_tx");
        expected_tx.results = '{default: '0};

        foreach (expected_tx.results[i]) begin
            contributors = 0;
            if (rf_arr[0].active_idx[i]) contributors++;
            if (rf_arr[1].active_idx[i]) contributors++;
            if (rf_arr[2].active_idx[i]) contributors++;
            if (rf_arr[3].active_idx[i]) contributors++;

            if (contributors > 1) begin
                $display("SCB OVERLAP: More than one reference stage is driving results[%0d]", i);
            end

            if (rf_arr[0].active_idx[i]) expected_tx.results[i] = rf_arr[0].pkt.results[i];
            else if (rf_arr[1].active_idx[i]) expected_tx.results[i] = rf_arr[1].pkt.results[i];
            else if (rf_arr[2].active_idx[i]) expected_tx.results[i] = rf_arr[2].pkt.results[i];
            else if (rf_arr[3].active_idx[i]) expected_tx.results[i] = rf_arr[3].pkt.results[i];
            else expected_tx.results[i] = 0;
        end

        $display("Expected: %p", expected_tx.results);
        $display("Actual: %p", mon_tx.results);
        if (expected_tx.results != mon_tx.results) begin
            num_mismatch++;
            $display("SCB_CMP Mismatch!\n");
        end else begin
            num_match++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("SCB_BLACKBOX_REPORT",
            $sformatf("Scoreboard results: %0d matched, %0d mismatched",
                      num_match, num_mismatch),
            UVM_LOW)
    endfunction

endclass