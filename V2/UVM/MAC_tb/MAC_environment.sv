class MAC_environment extends uvm_env;
    `uvm_component_utils(MAC_environment)

    MAC_scoreboard scb;
    MAC_agent agnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction 

    function build_phase(uvm_phase phase);
        super.build_phase(phase);
        scb = MAC_scoreboard::type_id::create("scb", this);
        agnt = MAC_agent::type_id::create("agnt", this);
    endfunction

    function connect_phase (uvm_phase phase);
        super.connect_phase(phase);
        agnt.mon.mon_ap.connect(scb.scb_imp);
    endfunction

endclass