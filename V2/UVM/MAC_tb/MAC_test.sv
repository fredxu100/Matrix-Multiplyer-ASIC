class MAC_test extends uvm_test;
    `uvm_component_utils(MAC_test)

    MAC_environment env;
    int cover_percent;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function build_phase (uvm_phase phase);
        super.build_phase(phase);
        env = MAC_environment::type_id::create("env", this);
    endfunction

    task run_phase (uvm_phase phase);
        int max_attempts = 100;
        int attempts = 0;
        MAC_sequence_rand seq1;
        phase.raise_objection(this);

        while (env.agnt.cov.cg_tx.get_inst_coverage() < 100 && attempts < max_attempts) begin
            MAC_sequence_rand seq = MAC_sequence_rand::type_id::create("seq");
            seq.start(env.agnt.seqncr);
            attempts++;
        end

        if (attempts >= max_attempts)
            `uvm_error("TEST_FAIL", "Coverage did not reach 100% before timeout")
        else
            `uvm_info("TEST_PASS", "Coverage reached 100%!", UVM_LOW)

        phase.drop_objection(this);
    endtask

endclass