class MAC_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(MAC_scoreboard)

    uvm_analysis_imp #(MAC_tx, MAC_scoreboard) scb_imp;
    MAC_reference rf;

    function new (string name, uvm_component parent);
        super.new(name, parent);
        scb_imp = new("scb_imp", this);
    endfunction

    function build_phase(uvm_phase phase);
        super.build_phase(phase);
        rf = MAC_reference::type_id::create("rf", this);
    endfunction

    function void write(MAC_tx tx);
        MAC_tx expected_tx;
        expected_tx = MAC_tx::type_id::create("expected_tx");

        rf.calculate(tx, expected_tx);

        if (!tx.compare(expected_tx)) begin
            `uvm_error("SCB_CMP", $sformatf("Mismatch!\nACT:%s\nEXP:%s", 
                        tx.sprint(), expected_tx.sprint()))
        end
    endfunction
endclass