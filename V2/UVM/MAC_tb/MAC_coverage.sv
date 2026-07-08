class MAC_coverage extends uvm_subscriber #(MAC_tx);
    `uvm_component_utils(MAC_coverage)

    MAC_tx tx;

    covergroup cg_tx with function sample(MAC_tx tx);
        
        option.per_instance = 1;
        
        cp_aout: coverpoint tx.aout {
            // bins low_range = { [0:7] };
            bins max_val   = { 255 }; 
        }

        // For bout: hit values [0:7] and a specific max value (assuming 255)
        cp_bout: coverpoint tx.bout {
            // bins low_range = { [0:7] };
            bins max_val   = { 255 };
        }

        // For accumulator: hit 0 and the max 24-bit value (16,777,215)
        cp_acc: coverpoint tx.accumulator {
            bins zero = {0};
            bins max  = { 16777215 }; // 2^24 - 1
        }
    endgroup
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_tx = new();
    endfunction

    function void write(MAC_tx t);
        tx = t;
        cg_tx.sample(tx);
    endfunction

endclass