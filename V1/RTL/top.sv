module top(
    input logic rst, clk, cpu_store_signal,
    input logic [31:0] data,
    output logic [8191:0] results
);
    logic [7:0] en, next_en;
    logic w_en;
    // ADDED: registered version of w_en to avoid single-cycle combinational pulse
    logic w_en_reg;

    logic [255:0] total_bus; 
    generate
        for (genvar i = 0; i < 8; i++) begin : buffer_gen
            // CHANGED: drive buffer w_en from w_en_reg instead of combinational w_en
            buffer_32 buffer (
                .clk(clk), .rst(rst),
                .reg_in(data),
                .r_en(en[i]),
                .w_en(w_en_reg),       // was: w_en
                .reg_out(total_bus[32*i +: 32])
            );
        end
    endgenerate

    always_comb begin
        case(en)
            8'b00000001: next_en = 8'b00000010;
            8'b00000010: next_en = 8'b00000100;
            8'b00000100: next_en = 8'b00001000;
            8'b00001000: next_en = 8'b00010000;
            8'b00010000: next_en = 8'b00100000;
            8'b00100000: next_en = 8'b01000000;
            8'b01000000: next_en = 8'b10000000;
            8'b10000000: next_en = 8'b00000000;
            8'b00000000: next_en = 8'b00000001;
            default:     next_en = en;
        endcase
    end

    always_ff @(posedge clk) begin
        if (rst) en <= 8'b00000001;
        else if (en == 8'b00000000) en <= next_en;  // auto-advance out of commit
        else if (cpu_store_signal)  en <= next_en;  // advance on each CPU write
    end

    assign w_en = (en == 8'b00000000);

    // ADDED: register w_en so it is stable for the full clock cycle
    // that buffer_32 sees it, instead of relying on a combinational decode
    // that races with en transitioning away from zero on the same edge.
    always_ff @(posedge clk) begin
        if (rst) w_en_reg <= 1'b0;
        else     w_en_reg <= w_en;
    end

    logic [127:0] bus_a, bus_b;
    assign bus_a = total_bus[127:0];
    assign bus_b = total_bus[255:128];

    // CHANGED: pass w_en_reg to systolic_array en as well
    systolic_array sys_arr(
        .clk(clk), .rst(rst),
        .en(w_en_reg),     // was: w_en
        .a(bus_a), .b(bus_b),
        .results(results)
    );

endmodule