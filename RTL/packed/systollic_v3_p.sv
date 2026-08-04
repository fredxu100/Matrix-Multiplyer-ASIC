module systollic_v3(
    input logic clk, rst, en,
    input logic [63:0] Ain, 
    input logic [63:0] Bin,
    output logic [151:0] results
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

    logic cycle_pass;
    //Assigns input values to ends of row/col mesh
    generate
        for (genvar i = 0; i < 8; i++) begin : input_map
            assign row[i][0] = Ain[i*8 +: 8];
            assign col[0][i] = Bin[i*8 +: 8];
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
                    .accumulator(internal_results[r][c])
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
            cycle_pass <= '0;
        end else if (en) begin //UPDATE: defend against stall corruptions
            if (en_cycles < 5'd23) 
                en_cycles <= en_cycles + 1'b1;
            else begin
                en_cycles <= '0;
                cycle_pass <= 1'b1;
            end
        end
    end

    //-----------------READ PTR ASSIGNMENT LOGIC--------------------//
    //Yosys synthesis rules, replaces modulo on results assignment and ABC combinational loop
    logic [2:0] read_ptr [7:0];

    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 8; i++) begin
                read_ptr[i] <= '0;
            end
        end else if (en) begin 
            for (int i = 0; i < 8; i++) begin
                if ((en_cycles >= (i + 8)) || cycle_pass) begin
                    read_ptr[i] <= read_ptr[i] + 1'b1;
                end
            end
        end
    end

    //------------------RESULTS ASSIGNMENT LOGIC-------------------//
    //Assign each mac_en "wavefront" to corresponding mac_en_counter value
    always_comb begin
        // 1. Default assignments to prevent synthesis latches
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                mac_en[i][j] = '0;
            end
        end
        results = '0;

        // 2. Combined Enable & Streaming Logic
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                // Enable PEs during their active 8-cycle window
                if ((en_cycles >= (i + j) || cycle_pass) && (en_cycles != '0 || en)) 
                    mac_en[i][j] = 1'b1;
            end

            if ((en_cycles >= (i + 8)) || cycle_pass) begin
                results[i*19 +: 19] = internal_results[i][read_ptr[i]];
            end
        end
    end

endmodule