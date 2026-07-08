class MAC_sequencer extends uvm_sequencer #(MAC_tx) ;
    `uvm_component_utils(MAC_sequencer)

    function new(string name = "MAC_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass