class MAC_sequence_rand extends uvm_sequence #(MAC_tx);
    `uvm_object_utils(MAC_sequence_rand)

    function new(string name);
        super.new(name);
    endfunction

    task body();
        MAC_tx tx;
        repeat(100) begin
            tx = MAC_tx::type_id::create("tx");
            if (!tx.randomize()) begin
                `uvm_error("SEQ", "Randomization failed")
            end
            
            start_item(tx);
            finish_item(tx);
        end 
    endtask
endclass