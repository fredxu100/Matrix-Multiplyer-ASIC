module MAC (
    input logic [7:0] ain, bin, 
    input logic clk, en, rst, 
    output logic [7:0] a, b,
    output logic [31:0] accumulator
);
    // REG 1: latch input data only when enabled (correct — en gates the load)
    always_ff @(posedge clk) begin
        if (rst) begin
            a <= 8'h00;
            b <= 8'h00;
        end else if (en) begin
            a <= ain;
            b <= bin;
        end
    end

    logic [31:0] mul_out;
    assign mul_out = a * b;

    always_ff @(posedge clk) begin
        if (rst) accumulator <= 32'h0;
        else accumulator <= accumulator + mul_out;
    end
  
endmodule