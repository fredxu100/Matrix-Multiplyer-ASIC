module systollic_v3(
    input logic clk, rst, en,
    input  logic [63:0]  Ain, 
    input  logic [63:0]  Bin,
    output logic [151:0] results
);
    //UPDATE: Updated MAC enable logic, MAC will no longer be pushing garbage values through 
    //Ain/Bin is split into 8 bytes, each corresponding to a seperate buffer, refer to sheets
    //Optomized throughput by streaming out results, removing built in stall time on initial designs

    //-------------------SYSTOLLIC ARRAY SETUP---------------------//
    //creates ever row/col wire connector, mac_en wire, and internal results counter
    //UPDATE NOTE: multi-dimensional arrays have been converted to packed vectors for YOSYS
    
    logic [7:0] row [0:71]; //all row connectors 1 extra row for Ain
    logic [7:0] col [0:71]; //all col connectors, 1 extra column for Bin
    logic mac_en [0:63];

    //TRADEOFF: Increasing area for simpler verification/programmer use
    logic [18:0] internal_results [0:63]; //USED TO HOLD MAC ACCUMULATOR VALUES TO BE STORED INTO RESULTS

    // index helpers so the r*W+c math isn't duplicated all over the place
    function automatic int row_idx(input int r, input int c); row_idx = r*9 + c; endfunction
    function automatic int col_idx(input int r, input int c); col_idx = r*8 + c; endfunction
    function automatic int pe_idx (input int r, input int c); pe_idx  = r*8 + c; endfunction

    //Assigns input values to ends of row/col mesh
    generate
        for (genvar i = 0; i < 8; i++) begin : input_map
            assign row[row_idx(i,0)] = Ain[i*8 +: 8];
            assign col[col_idx(0,i)] = Bin[i*8 +: 8];
        end
    endgenerate


    //generates and assigns mesh connector values to MAC
    generate
        for (genvar r = 0; r < 8; r++) begin: row_gen
            for (genvar c = 0; c < 8; c++) begin: col_gen
                MAC_v3 pe(
                    .clk(clk), .rst(rst), .en(mac_en[pe_idx(r,c)]),
                    .ain(row[row_idx(r,c)]),
                    .bin(col[col_idx(r,c)]),
                    .aout(row[row_idx(r,c+1)]),
                    .bout(col[col_idx(r+1,c)]),
                    .accumulator(internal_results[pe_idx(r,c)])
                );
            end
        end
    endgenerate

    //---------------MAC EN COUNTER LOGIC UPDATE-----------//
    //When sys_arr recieves en (coordinated by top to come wtih first Ain/Bin), begin counter that enables MAC units
    //Creates a diaganol wavefront when EN is triggered
    logic [4:0] en_cycles; //22 CYCLES

    always_ff @(posedge clk) begin
        if (rst) begin
            en_cycles <= '0;
        end else if (en) begin //UPDATE: defend against stall corruptions
            if (en_cycles < 5'd23)
                en_cycles <= en_cycles + 1'b1;
            else
                en_cycles <= '0;
        end
    end

    //------------------MAC_EN ASSIGNMENT--------------------------//
    //------------------RESULTS ASSIGNMENT LOGIC-------------------//
    //Assign each mac_en "wavefront" to corresponding mac_en_counter value
    always_comb begin
        // 1. Default assignments to prevent synthesis latches
        for (int i = 0; i < 8; i++) begin
            results[i*19 +: 19] = '0;
        end
        for (int k = 0; k < 64; k++) begin
            mac_en[k] = 1'b0;
        end

        // 2. Combined Enable & Streaming Logic
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                // Enable PEs during their active 8-cycle window
                if ({27'b0, en_cycles} >= (i + j) && {27'b0, en_cycles} < (i + j + 8) && (en_cycles != '0 || en))
                    mac_en[pe_idx(i,j)] = 1'b1;

                //TEMP CHANGE TO 9 TO FIT DRIVER ENABLE LOGIC
                // Stream results out row-by-row
                if ({27'b0, en_cycles} == (i + j + 9))
                    results[i*19 +: 19] = internal_results[pe_idx(i,j)];
            end
        end
    end

endmodule
