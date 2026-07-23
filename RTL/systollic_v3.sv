module systollic_v3(
    input logic clk, rst, en,
    input logic [7:0] Ain [7:0], 
    input logic [7:0] Bin [7:0],
    output logic [18:0] results [7:0]
);
    //UPDATE: Updated MAC enable logic, MAC will no longer be pushing garbage values through 
    //Ain/Bin is split into 8 bytes, each corresponding to a seperate buffer, refer to sheets
    //Optomized throughput by streaming out results, removing built in stall time on initial designs

    //-------------------SYSTOLLIC ARRAY SETUP---------------------//
    //creates ever row/col wire connector, mac_en wire, and internal results counter
    logic [7:0] row [7:0][8:0]; //all row connectors 1 extra row for Ain
    logic [7:0] col [8:0][7:0]; //all col connectors, 1 extra column for Bin
    logic mac_en [7:0][7:0];

    //TRADEOFF: Increasing area for simpler verification/programmer use
    logic [18:0] internal_results [7:0][7:0]; //USED TO HOLD MAC ACCUMULATOR VALUES TO BE STORED INTO RESULTS
    logic [2:0] internal_depths [7:0][7:0]; //USED TO HOLD MAC MATRIX DEPTH COUNTERS

    //Assigns input values to ends of row/col mesh
    generate
        for (genvar i = 0; i < 8; i++) begin : input_map
            assign row[i][0] = Ain[i];
            assign col[0][i] = Bin[i];
        end
    endgenerate

    //generates and assigns mesh connector values to MAC
    generate 
        for (genvar r = 0; r < 8; r++) begin: row_gen
            for (genvar c = 0; c < 8; c++) begin: col_gen
                MAC_v3 pe(
                    .clk(clk), .rst(rst), .en(mac_en[r][c]),
                    .ain(row[r][c]),
                    .bin(col[r][c]),
                    .aout(row[r][c+1]),
                    .bout(col[r+1][c]),
                    .accumulator(internal_results[r][c]),
                    .matrix_depth(internal_depths[r][c])
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
            mac_en <= '{default: 0};
        end else if (en) begin //UPDATE: defend against stall corruptions
            if (en_cycles < 5'd23) 
                en_cycles <= en_cycles + 1'b1;
            else
                en_cycles <= '0;
        end

        /*$display("Sys Ain %p, Sys Bin %p", Ain, Bin);
        $display("MAC [0,0]: Ain = %0d, Bin = %0d, Acc = %0d, Depth: %0d, .en %0d", row[0][0], col[0][0], internal_results[0][0], internal_depths[0][0], mac_en[0][0]);
        $display("MAC [7,0]: Ain = %0d, Bin = %0d, Acc = %0d, Depth: %0d, .en %0d\n", row[7][0], col[7][0], internal_results[7][0], internal_depths[7][0], mac_en[7][0]);*/

    end

    //------------------MAC_EN ASSIGNMENT--------------------------//
    //------------------RESULTS ASSIGNMENT LOGIC-------------------//
    //Assign each mac_en "wavefront" to corresponding mac_en_counter value
    always_comb begin
        // 1. Default assignments to prevent synthesis latches
        for (int i = 0; i < 8; i++) begin
            results[i] = '0;
        end

        // 2. Combined Enable & Streaming Logic
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                // Enable PEs during their active 8-cycle window
                if (en_cycles >= (i + j) && en_cycles < (i + j + 8) && (en_cycles != '0 || en)) 
                    mac_en[i][j] = 1'b1;

                //TEMP CHANGE TO 9 TO FIT DRIVER ENABLE LOGIC
                // Stream results out row-by-row
                if (en_cycles == (i + j + 9))
                    results[i] = internal_results[i][j];
            end
        end
    end

endmodule