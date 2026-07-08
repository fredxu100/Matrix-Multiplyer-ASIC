module systollic_v2(
    input logic clk, rst, en,
    input logic [63:0] Ain, Bin,
    output logic [2047:0] results
);
    //Ain/Bin is split into 8 bytes, each corresponding to a seperate buffer, refer to sheets

    //-------------------SYSTOLLIC ARRAY SETUP---------------------//
    //creates ever row/col wire connector, mac_en wire, and internal results counter
    logic [7:0] row [7:0][8:0]; //all row connectors 1 extra row for Ain
    logic [7:0] col [8:0][7:0]; //all col connectors, 1 extra column for Bin
    logic mac_en [7:0][7:0];
    logic [24:0] internal_results [7:0][7:0]; //stores MAC accumulator values
    //Assigns input values to ends of row/col mesh
    generate
        for (genvar i = 0; i < 8; i++) begin : input_map  // was < 16
            assign row[i][0] = Ain[i*8 +: 8]; //assigns every input row
            assign col[0][i] = Bin[i*8 +: 8]; //asigns every input column
        end
    endgenerate

    //generates and assigns mesh connector values to MAC
    generate 
        for (genvar r = 0; r < 8; r++) begin: row_gen
            for (genvar c = 0; c < 8; c++) begin: col_gen
                MAC_v2 pe(
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
    //When sys_arr recieves en (coordinated by top to come wtih first Ain/Bin), begin counter that enables/disables mesh
    //[8:1] correspond to turning on respective row/col of mac_en, ex 000000111 means row/col 1 and 2 are en
    //[0] 1 = on, 0 = off
    logic [8:0] mac_en_counter;
    always_ff @(posedge clk) begin
        if (rst) begin
            mac_en_counter <= '0;
        end else if (en) begin
            // Reset/Start the sequence
            mac_en_counter <= 9'b000000001;
        end else if (|mac_en_counter) begin // While counter is not 0
            if (!mac_en_counter[8]) begin
                // GROWTH PHASE: 000000001 -> 000000011 -> ... -> 111111111
                mac_en_counter <= (mac_en_counter << 1) | 9'b1;
            end else begin
                // SHRINK/SLIDE PHASE: 111111111 -> 111111110 
                mac_en_counter <= (mac_en_counter << 1) & 9'h1FF;
                // Hit 0 when finish
                if (mac_en_counter == 9'b100000001) begin
                    mac_en_counter <= 9'b000000000;
                end
            end
        end
    end

    //-----------------MAC_EN ASSIGNMENT-----------------//
    //Assign each mac_en "wavefront" to corresponding mac_en_counter value
    always_comb begin
        int layer;
        for (int i = 0; i < 8; i++) begin
            for (int j = 0; j < 8; j++) begin
                if (i > j) layer = i;
                else layer = j;
                // mac_en is high if the counter has reached this layer
                mac_en[i][j] = mac_en_counter[layer+1];
            
            end
        end 
    end

    //----------------PACKING---------------------------//
    //Internal results packed to get to the assigned result output value
    generate
        for (genvar r = 0; r < 8; r++) begin : pack_row   // was < 16
            for (genvar c = 0; c < 8; c++) begin : pack_col // was < 16
                assign results[(r*8 + c)*32 +: 32] = internal_results[r][c]; // was r*16+c
            end
        end
    endgenerate
endmodule