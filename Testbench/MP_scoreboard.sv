`include "uvm_macros.svh"
import uvm_pkg::*;
`uvm_analysis_imp_decl(_pkt)
`uvm_analysis_imp_decl(_matrix)

class MP_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(MP_scoreboard)
 
    uvm_analysis_imp_matrix #(matrix_tx, MP_scoreboard) matrix_imp; //observing matrix DUT input from driver
    uvm_analysis_imp_pkt #(pkt_tx, MP_scoreboard) pkt_imp; //monitor port
    
    MP_reference rf_arr [3]; //reference array to hold expected calculations of matricies in systollic array
    bit sys_en_delayed = 0; //simulates delay from buffer
    int num_mismatch = 0;
    int num_match = 0;
    int contributors; //checks for overlaps
    pkt_tx expected_tx; 
    int load_delay_cnt [3];
    
    function new(string name = "MP_scoreboard", uvm_component parent);
        super.new(name, parent);
        matrix_imp = new("matrix_imp", this);
        pkt_imp = new("pkt_imp", this);
        
        foreach (rf_arr[i]) begin //init rf arr 
            matrix_tx temp_mat = new("temp_mat");
            //0 default init so calculate_matrix() doesn't propagate X into results
            temp_mat.A_matrix = '{default: 8'h00};
            temp_mat.B_matrix = '{default: 8'h00};
            rf_arr[i] = new(temp_mat); 
            load_delay_cnt[i] = 0; // NEW: start every stage's delay counter at 0
        end
    endfunction

    //called every 8 cycles, linked to driver's input (I know thats bad practice)
    
    int load_counter = 0;
    function void write_matrix (matrix_tx matrix);
        //Acts like a reference queue. An update with queue logic may be better
        //$display("SCB: New matrix loaded in at %0d", (load_counter % 3));
        rf_arr[load_counter % 3] = new(matrix);
        
    // UPDATED: only the very first matrix ever loaded (load_counter == 0, which
        if (load_counter == 0)
            load_delay_cnt[0] = 2; // pre-satisfy the >= 2 check, no delay
        else
            load_delay_cnt[load_counter % 3] = 0; // normal case: reset, must warm up

        load_counter++;
    endfunction

    //NOTE: WRITE PKT MUST BE CALLED EVERY SINGLE CYCLE TO PREVENT STALL ERRORS
    function void write_pkt (pkt_tx mon_tx);
        //$display("New pkt written in");
        //Reset logic, clears reference array and resets delay
        if(mon_tx.rst) begin
            $display("RST ENABLED");
            sys_en_delayed = 0;
            foreach (rf_arr[i]) begin
                matrix_tx temp_mat = new("temp_mat");
                rf_arr[i] = new(temp_mat);
                load_delay_cnt[i] = 0;
            end
            return;
        end

        //1 cycle delay of buffer to systollic simulator
        //UPDATE: Previous sys_en didn't account for later systollic mistmatches
        if(sys_en_delayed) begin
            foreach (rf_arr[i]) begin 
                if (i < load_counter) begin
                    // UPDATED: every stage (including i == 0) now gates on its own
                    if (load_delay_cnt[i] >= 0) begin
                        rf_arr[i].stream_output();
                        //$display("SCB: rf_arr[%0d] results: %p", i, rf_arr[i].pkt.results);
                        //$display("Active Index: %p, Pipeline Depth %d\n", rf_arr[i].active_idx, rf_arr[i].pipeline_counter);
                    end else begin
                        load_delay_cnt[i]++; // still in this stage's 2-cycle warmup, tick it up
                        //$display("stage %0d warming up, delay = %0d", i, load_delay_cnt[i]);
                    end
                end
            end
        end 
        sys_en_delayed = mon_tx.en;
        
        expected_tx = pkt_tx::type_id::create("expected_tx");
        expected_tx.results = '{default: '0};
 
        //multiplex together values
        //UPDATE: USING ACTIVE_INX TO PREVENT MULTIPLEXING OVERLAPS, DEFENSIVE LOGIC
        foreach (expected_tx.results[i]) begin

            //----------------OVERLAP CHECK LOGIC------------------//
            contributors = 0;
            if (rf_arr[0].active_idx[i]) contributors++;
            if (rf_arr[1].active_idx[i]) contributors++;
            if (rf_arr[2].active_idx[i]) contributors++;
            //if (rf_arr[3].active_idx[i]) contributors++;
 
            if (contributors > 1) begin
                //$display("SCB OVERLAP: More than one reference stage is driving results[%0d]", i);
                foreach (rf_arr[j]) begin
                // Check if the handle is not null before accessing members
                    if (rf_arr[j] != null) begin
                        //$display("rf_arr[%0d].pkt.results = %p", j, rf_arr[j].pkt.results);
                    end
                end
            end

            //---------------ASSIGNMENT LOGIC--------------------//
            if (rf_arr[0].active_idx[i]) expected_tx.results[i] = rf_arr[0].pkt.results[i];
            else if (rf_arr[1].active_idx[i]) expected_tx.results[i] = rf_arr[0].pkt.results[i];
            else if (rf_arr[2].active_idx[i]) expected_tx.results[i] = rf_arr[0].pkt.results[i];
            //else if (rf_arr[3].active_idx[i]) expected_tx.results[i] = rf_arr[0].pkt.results[i];
            else expected_tx.results[i] = 0;
        end

        
        if (expected_tx.results != mon_tx.results) begin
            num_mismatch++;
            $display("SCB_CMP Mismatch!");
            $display ("Expected: %p", expected_tx.results);
            $display ("Actual: %p\n", mon_tx.results);
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