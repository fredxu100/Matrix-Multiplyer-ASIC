`include "uvm_macros.svh"
import uvm_pkg::*;
`uvm_analysis_imp_decl(_pkt)
`uvm_analysis_imp_decl(_matrix)

class MP_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(MP_scoreboard)

    uvm_analysis_imp_matrix #(matrix_tx, MP_scoreboard) matrix_imp;
    uvm_analysis_imp_pkt #(pkt_tx, MP_scoreboard) pkt_imp;

    MP_reference rf_arr [4]; //array of reference objects, stitched by scb
    int load_counter = 0; //counts which array value to load into
    int contributors; //checks for overlapping multiplexing

    int num_mismatch = 0;
    int num_match = 0;
    
    pkt_tx expected_tx;
    

    function new(string name = "MP_scoreboard", uvm_component parent);
        super.new(name, parent);
        matrix_imp = new("matrix_imp", this);
        pkt_imp = new("pkt_imp", this);

        //inits each reference object as 0
        foreach (rf_arr[i]) begin
            matrix_tx temp_mat = new("temp_mat");
            temp_mat.A_matrix = '{default: 8'h00};
            temp_mat.B_matrix = '{default: 8'h00};
            rf_arr[i] = new(temp_mat);
        end
    endfunction

    //loads matrix from driver into scb to be split and computed into references
    function void write_matrix (matrix_tx matrix);
        rf_arr[load_counter % 4] = new(matrix);
        load_counter++;
    endfunction

    //Pkt from monitor written
    function void write_pkt (pkt_tx mon_tx);

        //reset logic
        if (mon_tx.rst) begin
            foreach (rf_arr[i]) begin
                matrix_tx temp_mat = new("temp_mat");
                rf_arr[i] = new(temp_mat);
            end
            return;
        end

        //streaming reference objects based on loading timing
        foreach (rf_arr[i]) begin
            if (i < load_counter && mon_tx.en) begin
                rf_arr[i].stream_output();
            end
        end
        
        //creates expected tx reference object
        expected_tx = pkt_tx::type_id::create("expected_tx");
        expected_tx.results = '{default: '0};

        //check for overlapping contributors
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

        
        if (expected_tx.results != mon_tx.results) begin
            num_mismatch++;
            $display("SCB_CMP Mismatch!\n");
            $display("Expected: %p", expected_tx.results);
            $display("Actual: %p", mon_tx.results);
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