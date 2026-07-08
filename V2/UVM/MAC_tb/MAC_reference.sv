class MAC_reference;

    static int accum;

    function void calculate(MAC_tx tx, MAC_tx expected_tx);
        expected_tx.ain = tx.ain;
        expected_tx.bin = tx.bin;
        expected_tx.rst = tx.rt;
        expected_tx.en = tx.en;
        
        if (tx.rst) begin
            expected_tx.aout = 0;
            expected_tx.bout = 0;
            expected_tx.accumulator = 0;
            accum = 0;
        end else if (tx.en) begin
            accum += tx.ain * tx.bin;
            expected_tx.aout = tx.aout;
            expected_tx.bout = tx.bout;
            expected_tx.accumulator = accum;
        end

    endfunction
endclass