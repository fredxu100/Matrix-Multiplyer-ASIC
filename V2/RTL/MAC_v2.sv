module MAC_v2 (
    input logic [7:0] ain, bin, 
    input logic clk, en, rst, 
    output logic [7:0] aout, bout,
    output logic [24:0] accumulator
);  
    //Takes in ain and bin, passes directly to aout/bout on next clock cycle
    //ain * bin + accumulator to store value
    //systollic array passes en to individual MAC2

    // 1. Data Passthrough (Registers)
    always_ff @(posedge clk) begin
        if (rst) begin //clear aout/bout if rst
            aout <= '0;
            bout <= '0;
        end else if (en) begin //if enabled, pass in to out
            aout <= ain;
            bout <= bin;
        end
    end

    logic [15:0] mul_out;
    assign mul_out = ain * bin;

    //REG 3: accumulator counter
    always_ff @(posedge clk) begin
        if (rst) begin
            accumulator <= '0;
        end else if (en) begin
            accumulator <= accumulator + mul_out;
        end
    end
    
endmodule