`include "uvm_macros.svh"
import uvm_pkg::*;

class matrix_edge_tx extends uvm_sequence_item;
    `uvm_object_utils(matrix_edge_tx)

    rand logic [7:0] A_matrix [7:0][7:0];
    rand logic [7:0] B_matrix [7:0][7:0];
    logic [18:0] results_matrix [7:0][7:0];

    logic rst = 1'b0;
    logic en = 1'b1;

    function new (string name = "matrix_edge_tx");
        super.new(name);
    endfunction

    constraint c_matrix_A_edges {
        foreach (A_matrix[i, j]) {
            A_matrix[i][j] dist {
                8'h00 := 30, // 30% chance of 0
                8'hFF := 30, // 30% chance of Max (255)
                8'h7F := 10, // 10% chance of 127
                8'h80 := 10, // 10% chance of -128
                8'h55 := 10, // 10% chance of alternating bits
                8'hAA := 10  // 10% chance of inverted alternating bits
            };
        }
    }

    constraint c_matrix_B_edges {
        foreach (B_matrix[i, j]) {
            B_matrix[i][j] dist {
                8'h00 := 30,
                8'hFF := 30,
                8'h7F := 10,
                8'h80 := 10,
                8'h55 := 10,
                8'hAA := 10
            };
        }
    }

endclass