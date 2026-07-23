module MP_v3(
    input logic clk, rst, en,
    input logic [31:0] Ain1, Ain2, Bin1, Bin2,
    output logic [18:0] results [7:0]
);
//NOTE: A SENT BY ROWS, B !!MUST!! BE SENT IN BY COLUMNS (col1, col2, etc)


//UPDATE: Singular buffer unit (no longer 16 seperate buffers coordinated by top), modified load/store logic
//Loads in 4 RISC register values (4 x 32 bits) to get each cycle's values to send into the systollic array
//Condensed pipeline to combine loading/processing stages 
//Consolidated top/buffer into one module

//en triggers buffer to start sending data to systollic, TOP MUST SEND WITH FIRST AIN/BIN VALUES
//A/B: Ain1/Bin1 is LSB, Ain2/Bin2 is MSB. 1 gets sent to array before 2

    //Loads row1 (A), col1 (B), staggers the loading 
    logic [7:0] A [7:0][7:0];
    logic [7:0] B [7:0][7:0];

    logic [7:0] A_sys_in [7:0];
    logic [7:0] B_sys_in [7:0];
    logic sys_en;

    //-------------------SYSTOLLIC ARRAY DECLERATION---------------------//

    systollic_v3 sys_arr(
        .clk(clk), .rst(rst), .en(sys_en),
        .Ain(A_sys_in), .Bin(B_sys_in),
        .results(results)
    );

    //------------------SYSTOLLIC ENABLE LOGIC-------------------------//
    //enables systollic array 1 cycle after to wait for buffer value
    //VERIFY FOR CORNER CASES OF CONTROL LOGIC (ex. turning en on/off every other cycle)

    always_ff @(posedge clk) begin
        if (rst) begin
            sys_en <= 1'b0;
        end else begin
            sys_en <= en; // A pure, unconditional 1-cycle pipeline delay
        end
    end

    //--------------------LOAD LOGIC-----------------------//
    //UPDATE: Loading logic is now pipelined, does not stall
    //counter loads rows of A/B depending on counter value
    logic [2:0] load_counter;
    always_ff @(posedge clk) begin
        if (rst) begin
            A <= '{default: '0};
            B <= '{default: '0};
            load_counter <= '0;
        end else if (en) begin
            A[load_counter] <= '{Ain2[31:24], Ain2[23:16], Ain2[15:8], Ain2[7:0], Ain1[31:24], Ain1[23:16], Ain1[15:8], Ain1[7:0]};
            B[load_counter] <= '{Bin2[31:24], Bin2[23:16], Bin2[15:8], Bin2[7:0], Bin1[31:24], Bin1[23:16], Bin1[15:8], Bin1[7:0]};
            if (load_counter != 3'b111) begin
                load_counter <= load_counter + 1'b1; //counter counts to 8
                /*$display("Ain1: %0d, %0d, %0d, %0d", Ain1[31:24], Ain1[23:16], Ain1[15:8], Ain1[7:0]);
                $display("Ain2: %0d, %0d, %0d, %0d", Ain2[31:24], Ain2[23:16], Ain2[15:8], Ain2[7:0]);
                $display("Bin1: %0d, %0d, %0d, %0d", Bin1[31:24], Bin1[23:16], Bin1[15:8], Bin1[7:0]);
                $display("Bin2: %0d, %0d, %0d, %0d", Bin2[31:24], Bin2[23:16], Bin2[15:8], Bin2[7:0]);*/
                /*if (load_counter == '0) begin
                    $display("A: %p", A);
                    $display ("B: %p", B);
                end*/
            end else begin 
                load_counter <= '0;
            end
        end
    end

    //-------------------SEND LOGIC-----------------------//
    //SEND BEGINS ONE CYCLE AFTER LOADING
    //top will control the hold of en for 15 cycles (refer to sheets)

    logic [2:0] i;
    always_ff @(posedge clk) begin
        if (rst) begin
            A_sys_in <= '{default : 0};
            B_sys_in <= '{default : 0};
            i <= '0;
        end else if (sys_en) begin //sys_en logic, make sure that the delay is CORRECT
             for (int j = 0; j < 8; j++) begin 
                if (i < j) begin
                    A_sys_in[j] <= A[j][8 + i - j];
                    B_sys_in[j] <= B[j][8 + i - j]; 
                end
                else begin
                    A_sys_in[j] <= A[j][i - j];
                    B_sys_in[j] <= B[j][i - j];
                end
            end
            if (i != 3'b111) i <= i + 1'b1;
            else i <= '0;
        end
    end
endmodule