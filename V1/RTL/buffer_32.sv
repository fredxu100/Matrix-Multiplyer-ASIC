module buffer_32 (
    input logic clk,
    input logic rst,
    input logic [31:0] reg_in,
    input logic r_en,
    input logic w_en,
    output logic [31:0] reg_out
);
    // Reg 1 recieves data from CPU and writes it into a buffer to wait for synchronized output. 
    // Reg 2 outputs data to main 256 bit buffer that coordinates the inputs of systollic array

    //Reg 1
    logic [31:0] buffer;
    always_ff @(posedge clk) begin
        if (rst) buffer <= 32'h0;
        else if (r_en) buffer <= reg_in;
    end

    //Reg 2
    always_ff @(posedge clk) begin
        if (rst) reg_out <= 32'h0;
        else if (w_en) reg_out <= buffer;
        //do we want this to latch? should we keep the output to hold previous value until reset?
    end
    
endmodule