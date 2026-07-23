module MAC_v3 (
    input logic [7:0] ain, bin, 
    input logic clk, en, rst, 
    output logic [7:0] aout, bout,
    output logic [18:0] accumulator,
    output logic [2:0] matrix_depth
);  
    //Takes in ain and bin, passes directly to aout/bout on next clock cycle
    //ain * bin + accumulator to store value
    //systollic array passes en to individual MAC2

    // 1. Data Passthrough (Registers)
    logic depth_delay; //DRIVER LOGIC RESET TEMP
    always_ff @(posedge clk) begin
        if (rst) begin //clear aout/bout if rst
            matrix_depth <= '0;
            depth_delay <= '0;
            aout <= '0;
            bout <= '0;
        end else if (en) begin //if enabled, pass in to out
            aout <= ain;
            bout <= bin;
            if(matrix_depth != 3'b111 && depth_delay)
                matrix_depth <= matrix_depth + 1'b1;
            else begin
                depth_delay <= 1'b1;
                matrix_depth <= '0;
            end
        end
    end

    logic [15:0] mul_out;
    assign mul_out = ain * bin;

    //REG 3: accumulator counter
    always_ff @(posedge clk) begin
        if (rst) begin
            accumulator <= '0;
        end else if (en) begin
            if (matrix_depth == 0) //THIS LIKELY TPD
                accumulator <= mul_out;
            else
                accumulator <= accumulator + mul_out;
        end
    end
    
endmodule