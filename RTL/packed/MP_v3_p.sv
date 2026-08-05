module MP_v3(
    input logic clk, rst, en,
    input logic [31:0] Ain1, Ain2, Bin1, Bin2,
    output logic [151:0] results
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

    logic [63:0] A_sys_in;
    logic [63:0] B_sys_in;
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
    logic [2:0] load_counter = '0;
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 8; i++) begin
                for (int j = 0; j < 8; j++) begin
                    A[i][j] <= '0;
                    B[i][j] <= '0;
                end
            end
            load_counter <= '0;
        end else if (en) begin
            //MANUAL LOADING FOR YOSYS SYNTH
            A[load_counter][7] <= Ain2[31:24];
            A[load_counter][6] <= Ain2[23:16];
            A[load_counter][5] <= Ain2[15:8];
            A[load_counter][4] <= Ain2[7:0];
            A[load_counter][3] <= Ain1[31:24];
            A[load_counter][2] <= Ain1[23:16];
            A[load_counter][1] <= Ain1[15:8];
            A[load_counter][0] <= Ain1[7:0];

            B[load_counter][7] <= Bin2[31:24];
            B[load_counter][6] <= Bin2[23:16];
            B[load_counter][5] <= Bin2[15:8];
            B[load_counter][4] <= Bin2[7:0];
            B[load_counter][3] <= Bin1[31:24];
            B[load_counter][2] <= Bin1[23:16];
            B[load_counter][1] <= Bin1[15:8];
            B[load_counter][0] <= Bin1[7:0];

            if (load_counter != 3'b111) begin
                load_counter <= load_counter + 1'b1; //counter counts to 8
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
            i <= '0;
        end else if (sys_en) begin // FIX: must wait for sys_en (buffer is valid), not raw en
            if (i != 3'b111) i <= i + 1'b1;
            else i <= '0;
        end
    end

    // FIX: combinational readout - no extra register stage.
    // en_cycles/mac_en in systollic_v3 react to sys_en the instant it asserts,
    // so A_sys_in/B_sys_in must be valid that SAME cycle, not one cycle later.
    always_comb begin
        A_sys_in = '0;
        B_sys_in = '0;

        for (int j = 0; j < 8; j++) begin
            if (!sys_en) begin
                A_sys_in[j*8 +: 8] = '0;
                B_sys_in[j*8 +: 8] = '0;
            end
            else if (i < j) begin
                A_sys_in[j*8 +: 8] = A[j][8 - (j - i)];
                B_sys_in[j*8 +: 8] = B[j][8 - (j - i)];
            end
            else begin
                A_sys_in[j*8 +: 8] = A[j][i - j];
                B_sys_in[j*8 +: 8] = B[j][i - j];
            end
        end
    end
endmodule