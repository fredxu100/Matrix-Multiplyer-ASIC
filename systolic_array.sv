module systolic_array (
    input logic clk, rst, en,
    input logic [127:0] a, b,
    output logic [8191:0] results // Flattened 1D port for Synthesis/Yosys
);

    // 1. Internal 2D logic for simulator-friendly indexing
    logic [7:0] row [15:0][16:0];
    logic [7:0] col [16:0][15:0];
    logic [31:0] internal_results [15:0][15:0]; // <-- Add this!

    // Input row/col mesh connection (mapping flat inputs to internal 2D)
    generate
        for (genvar i = 0; i < 16; i++) begin
            assign row[i][0] = a[i*8 +: 8];
            assign col[0][i] = b[i*8 +: 8];
        end
    endgenerate

    // 2. Instantiation of MAC units using the INTERNAL 2D array
    generate
        for (genvar r = 0; r < 16; r++) begin : row_gen
            for (genvar c = 0; c < 16; c++) begin : col_gen
                MAC pe (.clk(clk), .rst(rst), .en(en), .ain(row[r][c]), .bin(col[r][c]), .a(row[r][c+1]), .b(col[r+1][c]), .accumulator(internal_results[r][c]) // <-- Connect here
                );
            end
        end
    endgenerate

    // 3. Map Internal 2D array to the Flattened 1D Output Port
    generate
        for (genvar r = 0; r < 16; r++) begin : pack_row
            for (genvar c = 0; c < 16; c++) begin : pack_col
                // This maps each 32-bit PE result to its slot in the 8192-bit bus
                assign results[(r*16 + c)*32 +: 32] = internal_results[r][c];
            end
        end
    endgenerate

endmodule