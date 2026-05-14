module systolic_top_apb_wrapper (
    input  logic        PCLK,    
    input  logic        PRESETn, 
    input  logic [31:0] PADDR,   
    input  logic        PSEL,    
    input  logic        PENABLE, 
    input  logic        PWRITE,  
    input  logic [31:0] PWDATA,  
    output logic [31:0] PRDATA,  
    output logic        PREADY,  
    output logic [8191:0] results_out 
);

    logic [31:0] data_in;
    logic cpu_store_signal;
    logic rst = ~PRESETn;

    top matrix_top (
        .clk(PCLK),
        .rst(rst),
        .cpu_store_signal(cpu_store_signal),
        .data(data_in),
        .results(results_out) 
    );

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            data_in          <= 32'h0;
            cpu_store_signal <= 1'b0;
        end else begin
            cpu_store_signal <= 1'b0; 
            if (PSEL && PENABLE && PWRITE) begin
                case (PADDR[7:0]) 
                    8'h00: data_in          <= PWDATA;
                    8'h04: cpu_store_signal <= PWDATA[0];
                endcase
            end
        end
    end

    always_comb begin
        PRDATA = 32'h0;
        if (PSEL && PENABLE && !PWRITE) begin
            if (PADDR[11:0] >= 12'h100) begin
                logic [7:0] idx; 
                idx = (PADDR[11:0] - 12'h100) >> 2;   // word index 0..255
                PRDATA = results_out[idx * 32 +: 32];
            end
        end
    end

    assign PREADY = 1'b1;

endmodule