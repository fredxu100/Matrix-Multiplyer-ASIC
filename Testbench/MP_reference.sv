class MP_reference;
 
    int pipeline_counter; //tracks depth of current obj in pipeline
    matrix_tx matrix; 
    pkt_tx pkt;
    int i; //counter for results
    logic active_idx[7:0]; //UPDATE: which pkt.results[] index (if any) this stage wrote this cycle, -1 = none

    function new(matrix_tx matrix);
        this.pipeline_counter = 0;
        this.matrix = new matrix; //DEEP COPY
        this.pkt = new();
        calculate_matrix(); //calculates expected matrix values
    endfunction

    //MODIFY PIPELINE COUNTER TO CHANGE PIPELINING DEPTH VERIFICATION 
    //!!!!DOUBLE CHECK THIS STREAM LOGIC DELAY WITH THE DRIVER/MONITOR DELAY!!!!!
    function void stream_output();
        //assigns each value to 0 of results, assists with | multiplexing
        foreach(pkt.results[idx]) pkt.results[idx] = '0;
        active_idx = '{default: 1'b0};  // reset all defensive multiplexing checks

        //stream_output called when sys_arr is enabled
        //!!!!DOUBLE CHECK THIS DELAY!!!! (might be >8, < 24)
        if (pipeline_counter > 8 && pipeline_counter < 25) begin
            i = pipeline_counter - 9;
            for(int j = 0; j < 8; j++) begin
                for (int k = 0; k < 8; k++) begin
                    if (j + k == i) begin 
                        //tracks internal matrix and selects diaganol values to simulate staggered pipeline
                        pkt.results[j] = matrix.results_matrix[j][k];
                        active_idx[j] = 1'b1;  // mark this index as active
                    end
                end
            end
        end
 
        //NOTE: pipelined is only increased when called by SCB, ensures EN stall logic is correct
        pipeline_counter++;
    endfunction

    //Fills out expected matrix values, matrix multiplication
    function void calculate_matrix ();
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                matrix.results_matrix[i][j] = 0;
                for (int k = 0; k < 8; k++) begin
                    matrix.results_matrix[i][j] += (matrix.A_matrix[i][k] * matrix.B_matrix[j][k]);
                end
            end
        end

        $display("REF EXPECTED MATRIX: %p", matrix.results_matrix);
    endfunction

endclass